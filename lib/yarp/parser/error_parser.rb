# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: ErrorParser implements a FSM for parsing Yarp's Error responses
    # into a concrete instance.
    class ErrorParser
      def initialize
        @magic = []
        @scalar_parser = ScalarParser.new
        @map_parser = MapParser.new
        @id_parser = StringParser.new
      end

      def feed(byte)
        return feed_magic(byte) if @magic.length < 3
        return feed_kind(byte) if @kind.nil?
        return feed_headers(byte) if @headers.nil?
        return feed_id(byte) if @id.nil?
        return false unless feed_user_data(byte)

        [true, Yarp::Proto::Error.new(@kind, @headers, @id, @user_data)]
      end

      def feed_magic(byte)
        @magic << byte
        return false unless @magic.length == 3
        raise CorruptStreamError if @magic.pack("C*") != Proto::MAGIC_ERROR

        false
      end

      def feed_kind(byte)
        ok, v = @scalar_parser.feed(byte)
        @kind = v.to_i if ok
        false
      end

      def feed_headers(byte)
        ok, v = @map_parser.feed(byte)
        if ok
          @headers = v
          @map_parser.reset
        end
        false
      end

      def feed_id(byte)
        ok, v = @id_parser.feed(byte)
        @id = v if ok
        false
      end

      def feed_user_data(byte)
        ok, v = @map_parser.feed(byte)
        return false unless ok

        @user_data = v
        true
      end
    end
  end
end
