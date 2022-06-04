# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: MapParser implements a FSM for parsing Yarp's Map values
    class MapParser
      def initialize
        @scalar_parser = ScalarParser.new
        @read = 0
        @keys = []
        @values = []
      end

      def feed(byte)
        return feed_size(byte) if @size.nil?
        return feed_klen(byte) if @k_len.nil?
        return feed_k(byte) unless @k_len.zero?
        return feed_vlen(byte) if @v_len.nil?

        return false if !@v_len.zero? && !feed_v(byte)
        return unless @v_len.zero?
        raise Error, "uneven map values" if @keys.length != @values.length

        [true, @keys.zip(@values).to_h]
      end

      def feed_size(byte)
        ok, v = @scalar_parser.feed(byte)
        if ok
          return true, {} if v.zero?

          @size = v
          @scalar_parser.reset
        end
        false
      end

      def feed_klen(byte)
        ok, v = @scalar_parser.feed(byte)
        @read += 1
        if ok
          @scalar_parser.reset
          @k_len = v
        end
        false
      end

      def feed_vlen(byte)
        ok, v = @scalar_parser.feed(byte)
        @read += 1
        if ok
          @scalar_parser.reset
          @v_len = v
        end
        false
      end

      def feed_k(byte)
        @k_len -= 1
        @current_parser = Parser.detect_parser(byte) if @current_parser.nil?
        ok, v = @current_parser.feed(byte)
        if ok
          @keys << v
          @current_parser = nil
        end
        false
      end

      def feed_v(byte)
        @v_len -= 1
        @current_parser = Parser.detect_parser(byte) if @current_parser.nil?
        ok, v = @current_parser.feed(byte)
        if ok
          @values << v
          @current_parser = nil
        end
        @v_len.zero?
      end

      def reset
        @scalar_parser.reset
        @size = nil
        @read = 0
        @keys.clear
        @values.clear
        @k_len = nil
        @v_len = nil
        @current_parser = nil
      end
    end
  end
end
