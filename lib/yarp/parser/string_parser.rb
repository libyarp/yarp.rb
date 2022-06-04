# frozen_string_literal: true

module Yarp
  module Parser
    # Internal: StringParser implements a FSM for parsing Yarp's string values
    class StringParser
      def initialize
        @size = nil
        @scalar_parser = ScalarParser.new
        @buf = []
      end

      def feed(byte)
        if @size.nil?
          ok, val = @scalar_parser.feed(byte)
          if ok
            @size = val.to_i
            return true, "" if @size.zero?
          end
          return false
        end

        @buf << byte
        return true, @buf.pack("C*").force_encoding("UTF-8") if @buf.length == @size

        false
      end
    end
  end
end
