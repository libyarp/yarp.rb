# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: RequestParser implements a FSM for parsing Yarp's Request
    # headers into concrete instances
    class RequestParser
      def initialize
        @magic = []
        @scalar_parser = ScalarParser.new
        @header_parser = MapParser.new
        @headers = nil
      end

      def feed(byte)
        return feed_magic(byte) if @magic.length < 3
        return feed_size(byte) if @size.nil?
        return feed_method_id(byte) if @method.nil?
        return unless feed_header(byte)
        raise CorruptStreamError if @size != 0

        [true, Yarp::Proto::Request.new(@method, @headers)]
      end

      def feed_magic(byte)
        @magic << byte

        return if @magic.length != 3
        raise CorruptStreamError if @magic.pack("C*") != Proto::MAGIC_REQUEST
      end

      def feed_size(byte)
        ok, v = @scalar_parser.feed(byte)
        return false unless ok

        @size = v.to_i
        @scalar_parser.reset
        false
      end

      def feed_method_id(byte)
        @size -= 1
        ok, v = @scalar_parser.feed(byte)
        return false unless ok

        @method = v.to_i
        false
      end

      def feed_header(byte)
        raise CorruptStreamError if @size <= 0

        @size -= 1
        ok, v = @header_parser.feed(byte)
        return false unless ok

        @headers = v
        true
      end
    end
  end
end
