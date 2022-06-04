# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: FloatParser implements a FSM for parsing Yarp's Float values
    class FloatParser
      def initialize
        @value = 0.0
        @first_byte = true
        @wants = 0
        @buf = []
      end

      def feed(byte)
        if @first_byte
          @first_byte = false
          @bits = (byte & 0x10) == 0x10 ? 64 : 32
          @wants = @bits / 8
          return (byte & 0x8) == 0x8, @value
        end

        @buf << byte
        return false if @buf.length != @wants

        [true, result]
      end

      def result
        @buf.pack("C*").unpack1(@bits == 32 ? "e" : "E")
      end
    end
  end
end
