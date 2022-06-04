# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: ResponseParser implements a FSM for parsing Yarp's Response
    # headers into concrete instances
    class ResponseParser
      def initialize
        @magic = []
        @scalar_parser = ScalarParser.new
        @header_parser = MapParser.new
      end

      def feed(byte)
        return feed_magic(byte) if @magic.length < 3
        return feed_header(byte) if @headers.nil?

        feed_bool(byte)
      end

      def feed_magic(byte)
        @magic << byte

        return if @magic.length != 3
        raise CorruptStreamError if @magic.pack("C*") != Proto::MAGIC_RESPONSE

        false
      end

      def feed_header(byte)
        ok, v = @header_parser.feed(byte)
        return false unless ok

        @headers = v
        false
      end

      def feed_bool(byte)
        ok, v = @scalar_parser.feed(byte)
        raise CorruptStreamError unless ok

        [true, Yarp::Proto::Response.new(@headers, v.yarp_bool)]
      end
    end
  end
end
