# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: ArrayParser implements a FSM for parsing Yarp's Arrays
    class ArrayParser
      def initialize
        @first_byte = true
        @size = nil
        @scalar_parser = ScalarParser.new
        @current_parser = nil
        @arr = []
      end

      def feed(byte)
        return feed_size(byte) if @size.nil?

        if @current_parser.nil?
          detect_parser(byte)
        else
          feed_parser(byte)
        end
        return true, @arr if @size.zero?

        false
      end

      def feed_size(byte)
        ok, v = @scalar_parser.feed(byte)
        if ok
          return true, [] if v.zero?

          @size = v.to_i
        end
        false
      end

      def detect_parser(byte)
        @size -= 1
        @current_parser = Parser.detect_parser(byte)
        arr << nil if @current_parser.nil?

        return unless @current_parser

        ok, v = @current_parser.feed(byte)
        return unless ok

        @arr << v
        @current_parser = nil
      end

      def feed_parser(byte)
        @size -= 1
        ok, v = @current_parser.feed(byte)
        return unless ok

        @arr << v
        @current_parser = nil
      end
    end
  end
end
