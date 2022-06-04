# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: ScalarParser implements a FSM for parsing Yarp's Scalar types
    class ScalarParser
      def initialize
        reset
      end

      def reset
        @value = 0
        @signed = false
        @first_byte = true
      end

      def feed(byte)
        if @first_byte
          @first_byte = false
          @value = (byte & 0xE) >> 1
          @signed = (byte & 0x10) == 0x10
          return (byte & 0x1).zero?, result
        end

        @value <<= 7
        @value |= (byte >> 1)
        [(byte & 0x1).zero?, result]
      end

      def result
        Yarp::Proto::Scalar.new(@signed, @value)
      end
    end
  end
end
