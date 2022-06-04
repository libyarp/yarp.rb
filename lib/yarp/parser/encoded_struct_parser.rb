# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: EncodedStructParser implements a FSM for parsing Yarp's
    # Structures into EncodedStruct instances.
    class EncodedStructParser
      def initialize
        @scalar_parser = ScalarParser.new
        @fields = []
        @id = []
      end

      def feed(byte)
        return feed_size(byte) if @size.nil?
        return feed_id(byte) if @id.length != 8

        feed_parser(byte)
        return false unless @size.zero?

        [true, Proto::EncodedStruct.new.tap do |i|
          i.id = @id.pack("C*").unpack1(">Q")
          i.fields = @fields
        end]
      end

      def feed_size(byte)
        ok, v = @scalar_parser.feed(byte)
        return false unless ok
        return true, nil if v.zero?

        @scalar_parser.reset
        raise SizeTooLargeError if v >= Proto::SIZE_LIMIT

        @size = v.to_i
        false
      end

      def feed_id(byte)
        @size -= 1
        @id << byte
        false
      end

      def feed_parser(byte)
        @size -= 1
        if @current_parser.nil?
          @current_parser = Parser.detect_parser(byte)
          if @current_parser.nil?
            @fields << nil
            return
          end
        end

        ok, v = @current_parser.feed(byte)
        return unless ok

        @current_parser = nil
        @fields << v
      end
    end
  end
end
