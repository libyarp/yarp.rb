# frozen_string_literal: true

module Yarp
  class Server
    # Internal: Driver provides a implementation responsible for receiving data
    # from a remote endpoint, parsing it, and executing the whole handler
    # lifecycle operations required to service the incoming connection.
    class Driver
      attr_reader :logger, :request

      STATE_NEW               = 0
      STATE_WAITING_HEADERS   = 1
      STATE_RECEIVED_HEADERS  = 2
      STATE_RECEIVING_BODY    = 3
      STATE_RECEIVED_BODY     = 4
      STATE_WRITING_RESPONSE  = 5
      STATE_WROTE_RESPONSE    = 6
      STATE_ERRORED           = 7
      STATE_CLOSED            = 8

      STATE_TO_SYM = {
        STATE_NEW => :new,
        STATE_WAITING_HEADERS => :waiting_headers,
        STATE_RECEIVED_HEADERS => :received_headers,
        STATE_RECEIVING_BODY => :receiving_body,
        STATE_RECEIVED_BODY => :received_body,
        STATE_WRITING_RESPONSE => :writing_response,
        STATE_WROTE_RESPONSE => :wrote_response,
        STATE_ERRORED => :errored,
        STATE_CLOSED => :closed
      }.freeze

      def initialize(conn)
        @conn = conn
        @state = STATE_NEW
        @id = SecureRandom.uuid
        @connected_at = Time.stamp
        @config = ::Yarp.configuration
        @logger ||= Yarp.logger.with_fields(request_id: @id)
        @request_parser = Yarp::Parser::RequestParser.new
        @buf = StringIO.new
        logger.info("Transaction started")
      end

      def state
        STATE_TO_SYM[@state]
      end

      def dispatch_byte(byte)
        return feed_request_body(byte) unless @request.nil?

        feed_request_parser(byte)
      rescue Exception => e
        handle_error(e)
      end

      def feed_request_parser(byte)
        @state = STATE_WAITING_HEADERS
        ok, v = @request_parser.feed(byte)
        return unless ok

        @state = STATE_RECEIVED_HEADERS
        @headers_parsed_at = Time.stamp
        @request = v
        # TODO: Middlwares
        determine_handler
      rescue Yarp::CorruptStreamError => e
        logger.error("Corrupt stream during request parsing", e)
        drop!
      end

      def determine_handler
        @handler_meta = Yarp::Registry.find_method(@request.method_id)
        raise Proto::Error.unimplemented_method unless @handler_meta

        begin
          @handler = @handler_meta[:class].new(self, @request)
        rescue StandardError => e
          logger.error("Error initializing new instance of #{@handler_meta[:class]}", e)
          return internal_error!
        end
        raise Proto::Error.unimplemented_method unless @handler.respond_to? @handler_meta[:name]
      end

      def feed_request_body(byte)
        @state = STATE_RECEIVING_BODY
        @body_parser ||= Yarp::Parser.detect_parser(byte)
        ok, v = @body_parser.feed(byte)
        return unless ok

        @request_body = v
        prepare_request_body
      rescue Yarp::Error => e
        logger.error("Error parsing body", e, parser: @body_parser&.class&.name)
        drop!
      end

      def internal_error!
        handle_error(Yarp::Proto::Error.internal_error)
      end

      def handle_error(ex)
        # Depending on the current connection state, we may not be able to emit
        # an error response. So let's naturally, log it, and then see what we
        # can do with it.
        logger.error("Invoked error handler", ex)

        # If we have not yet started writing a response, we should be good to
        # write the error and just drop the connection right after.
        if @state >= STATE_WRITING_RESPONSE
          logger.error("Not sending error payload due to current connection state", state: state)
          return
        end

        @state = STATE_ERRORED
        return unless ex.is_a? Yarp::Proto::Error

        ex.encode(@buf)
        flush_internal_buffer
        drop!(flush: true)
        nil
      end

      def drop!(flush: false)
        if flush
          @conn.close_connection_after_writing
        else
          @conn.close_connection
        end
      end

      def prepare_request_body
        @state = STATE_RECEIVED_BODY
        @request_body = @request_body.specialize if @request_body.respond_to? :specialize

        if @handler_meta[:receives].nil? && !@request_body.nil?
          logger.warn "Rejecting request due to inconsistent request body type",
                      wants: :nothing,
                      received: @request_body.class.name
          raise Yarp::Proto::Error.type_mismatch
        end

        unless @request_body.is_a? @handler_meta[:receives]
          logger.warn "Rejecting request due to inconsistent request body type",
                      wants: @handler_meta[:receives]&.name,
                      received: @request_body.class.name
          raise Yarp::Proto::Error.type_mismatch
        end

        invoke_handler
      end

      def invoke_handler
        result = @handler.send(@handler_meta[:name], @request_body)
        return finish_stream if @handler_meta[:streams]

        @state = STATE_WRITING_RESPONSE
        return_type = @handler_meta[:returns]
        result = nil if return_type.nil?

        if return_type&.ancestors&.include?(Yarp::Structure)
          result = case result
                   when Hash
                     return_type.new(**result)
                   when Array
                     return_type.new(*result)
                   else
                     return_type.new(result)
                   end
        end

        if !result.nil? && !result.is_a?(return_type)
          # Aight, this is the worst case scenario possible: We have a response,
          # but the type is incorrect. I really do hope this condition is
          # noticed during tests.
          raise "Could not convert #{result.inspect} (#{result.class.name}) " \
                "to expected return type #{return_type.inspect}"
        end

        Yarp::Proto::Response.new(@handler.response_headers, false).encode(@buf)
        flush_internal_buffer
        Yarp::Proto.encode(@buf, result, as: return_type)
        flush_internal_buffer
        @state = STATE_WROTE_RESPONSE
      rescue Exception => e
        handle_error(e)
      end

      def flush_internal_buffer
        @conn.send_data(@buf.string)
        @buf.truncate(0)
        @buf.rewind
      end

      def begin_streaming(_headers)
        raise "Driver state does not allow streaming" if @state != STATE_RECEIVED_BODY
        raise "Driver is already streaming" if @streaming

        @streaming = true
        @state = STATE_WRITING_RESPONSE
        Yarp::Proto::Response.new(@handler.response_headers, true).encode(@buf)
        flush_internal_buffer
      end

      def push_stream(value)
        return_type = @handler_meta[:returns]
        if return_type&.ancestors&.include?(Yarp::Structure)
          value = case value
                  when Hash
                    return_type.new(**value)
                  when Array
                    return_type.new(*value)
                  else
                    return_type.new(value)
                  end
        end

        unless value.is_a? return_type
          logger.warn "Skipping stream item due to invalid type. " \
                      "Wants #{return_type.name}, received #{value.class.name}"
          return
        end

        Yarp::Proto.encode(@buf, value, as: return_type)
        flush_internal_buffer
      end

      def handler_can_stream?
        @handler_meta[:streams]
      end

      def finish_stream
        @state = STATE_WROTE_RESPONSE
        drop! flush: true
      end

      def notify_unbind
        logger.info("Transaction statistics",
                    started_at: @connected_at.rfc3339,
                    duration_sec: Time.stamp - @connected_at,
                    headers_received_in_sec: Time.stamp - @headers_parsed_at)
      end
    end
  end
end
