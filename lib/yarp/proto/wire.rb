# frozen_string_literal: true

module Yarp
  # Internal: Module Proto defines all types and helpers for handling Protocol
  # entities and byte streams.
  module Proto
    MAGIC_REQUEST  = "\x79\x79\x72"
    MAGIC_RESPONSE = "\x79\x79\x52"
    MAGIC_ERROR    = "\x79\x79\x65"

    # Internal: Request represents a set of request headers along with a method
    # identifier to be invoked.
    class Request
      attr_accessor :method_id, :headers

      def initialize(method, headers)
        @method_id = method
        @headers = headers || {}
      end

      def encode(into)
        buf = StringIO.new
        Scalar.encode_integer(buf, @method_id, signed: false)
        Map.new(:string, :string).encode(buf, @headers)
        into.write(MAGIC_REQUEST)
        Scalar.encode_integer(into, buf.length, signed: false)
        into.write(buf.string)
      end

      def self.decode(io)
        magic = io.read(3)
        raise CorruptStreamError if magic != MAGIC_REQUEST

        len = Scalar.decode(io.read(1), io)
        lr = LimitedIO.new(io, len)
        method = Scalar.decode(lr.read(1), lr)
        h = Map.decode(lr.read(1), lr)

        new(method, h)
      end
    end

    # Internal: Response represents a set of request headers along with an
    # indicator of whether the response will be streamed.
    class Response
      attr_accessor :headers, :stream

      def initialize(headers, stream)
        @headers = headers
        @stream = stream
      end

      alias stream? stream

      def encode(into)
        into.write(MAGIC_RESPONSE)
        Map.new(:string, :string).encode(into, headers)
        Scalar.encode_boolean(into, @stream)
      end

      def self.decode(io)
        magic = io.read(3)
        raise CorruptStreamError if magic != MAGIC_RESPONSE

        headers = Map.decode(io.read(1), io)
        stream = Scalar.decode(io.read(1), io).yarp_bool
        new(headers, stream)
      end
    end

    # Internal: Error represents a server response indicating that an error
    # interrupted the current operation.
    class Error < RuntimeError
      INTERNAL_ERROR        = 0
      MANAGED_ERROR         = 1
      REQUEST_TIMEOUT       = 2
      UNIMPLEMENTED_METHOD  = 3
      TYPE_MISMATCH         = 4
      UNAUTHORIZED          = 5
      BAD_REQUEST           = 6

      KIND_TO_SYM = {
        INTERNAL_ERROR => :internal_error,
        MANAGED_ERROR => :managed_error,
        REQUEST_TIMEOUT => :request_timeout,
        UNIMPLEMENTED_METHOD => :unimplemented_method,
        TYPE_MISMATCH => :type_mismatch,
        UNAUTHORIZED => :unauthorized,
        BAD_REQUEST => :bad_request
      }.freeze

      attr_accessor :kind, :headers, :identifier, :user_data

      def self.internal_error(identifier: nil, headers: nil, user_data: nil)
        new(INTERNAL_ERROR, headers, identifier, user_data)
      end

      def self.request_timeout(identifier: nil, headers: nil, user_data: nil)
        new(REQUEST_TIMEOUT, headers, identifier, user_data)
      end

      def self.unimplemented_method(identifier: nil, headers: nil, user_data: nil)
        new(UNIMPLEMENTED_METHOD, headers, identifier, user_data)
      end

      def self.type_mismatch(identifier: nil, headers: nil, user_data: nil)
        new(TYPE_MISMATCH, headers, identifier, user_data)
      end

      def self.unauthorized(identifier: nil, headers: nil, user_data: nil)
        new(UNAUTHORIZED, headers, identifier, user_data)
      end

      def self.bad_request(identifier: nil, headers: nil, user_data: nil)
        new(BAD_REQUEST, headers, identifier, user_data)
      end

      def self.generic(identifier, headers: nil, user_data: nil)
        new(MANAGED_ERROR, headers, identifier, user_data)
      end

      def initialize(kind, headers, identifier, user_data)
        super()
        @kind = kind
        @headers = headers || {}
        @identifier = identifier || ""
        @user_data = user_data || {}
      end

      def encode(into)
        into.write(MAGIC_ERROR)
        Scalar.encode_integer(into, @kind, signed: false)
        sts_map = Map.new(:string, :string)
        sts_map.encode(into, @headers)
        String.encode(into, @identifier)
        sts_map.encode(into, @user_data)
      end

      def self.decode(io)
        magic = io.read(3)
        raise CorruptStreamError if magic != MAGIC_ERROR

        kind = Scalar.decode(io.read(1), io).to_i
        headers = Map.decode(io.read(1), io)
        identifier = String.decode(io.read(1), io)
        user_data = Map.decode(io.read(1), io)

        new(kind, headers, identifier, user_data)
      end

      def inspect
        opts = {
          kind: KIND_TO_SYM[@kind] || :invalid,
          headers: @headers.inspect,
          identifier: @identifier.inspect,
          user_data: @user_data.inspect
        }.map { |k, v| "#{k}=#{v}" }.join(" ")
        "#<#{self.class.name}:#{format("0x%08x", object_id * 2)} #{opts}>"
      end
      alias to_s inspect

      def respond_to_missing?(method_name, include_private = false)
        KIND_TO_SYM.values.include?(method_name.to_s.gsub(/\?$/, "").to_sym) || super
      end

      def method_missing(name, *args, &block)
        if name.end_with?("?") && KIND_TO_SYM.values.include?(name.to_s.gsub(/\?$/, "").to_sym)
          return KIND_TO_SYM[kind] == name.to_s.gsub(/\?$/, "").to_sym
        end

        super
      end
    end
  end
end
