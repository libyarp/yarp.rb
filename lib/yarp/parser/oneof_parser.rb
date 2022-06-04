# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: OneofParser implements a FSM for parsing Yarp's Oneof values
    class OneofParser
      def initialize
        @scalar_parser = ScalarParser.new
      end

      def feed(byte)
        return feed_size(byte) if @size.nil?
        return feed_index(byte) if @index.nil?

        feed_parser(byte)
      end

      def feed_size(byte)
        ok, v = @scalar_parser.feed(byte)
        return false unless ok

        @size = v.to_i
        return true, nil if @size.zero?
        raise SizeTooLargeError if @size >= Proto::SIZE_LIMIT

        @scalar_parser.reset
        false
      end

      def feed_index(byte)
        @size -= 1
        ok, v = @scalar_parser.feed(byte)
        return false unless ok

        @index = v
        false
      end

      def feed_parser(byte)
        @size -= 1
        if @current_parser.nil?
          @current_parser = Parser.detect_parser(byte)
          return @size.zero?, nil if @current_parser.nil?
        end

        ok, v = @current_parser.feed(byte)
        return true, Proto::Oneof.new(@index, v) if ok && @size.zero?

        false
      end
    end
  end
end
