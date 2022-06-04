# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: Scalar implements an encoder and decoder for Yarp's Scalar values
    class Scalar
      MAX_LEN = 16
      class << self
        def encode(value)
          value &= 0xFFFFFFFF_FFFFFFFF
          pos = MAX_LEN - 1
          data = [0] * 16
          while (value << 1) > 0x7
            data[pos] = (value & 0x7F) << 1
            data[pos] |= 1 if pos != MAX_LEN - 1
            pos -= 1
            value >>= 7
          end
          data[pos] = (value << 1) & 0x7
          data[pos] |= 0x1 if pos < MAX_LEN - 1
          data[pos..].pack("C*")
        end

        def decode(header, io)
          header = header.getbyte(0)
          value = (header & 0xE) >> 1
          signed = (header & 0x10) == 0x10
          if (header & 0x1) == 0x1
            loop do
              value <<= 7
              r = io.read(1).getbyte(0)
              value |= (r >> 1)
              break if (r & 0x01) != 0x01
            end
          end

          new(signed, value)
        end

        def encode_integer(into, value, signed: false)
          data = encode(value).tap do |b|
            b.setbyte(0, b.getbyte(0) | (signed ? 0x30 : 0x20))
          end
          if into.nil?
            data
          else
            into.write(data)
          end
        end

        def encode_boolean(into, value)
          into.write(value ? "\x30" : "\x20")
        end
      end

      def initialize(signed, val)
        @signed = signed
        @val = signed ? [val].pack("Q").unpack1("q") : val
      end

      def signed?
        @signed
      end

      def method_missing(name, *args, &block)
        if @val.respond_to?(name)
          @val.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super || @val.respond_to?(method_name, include_private)
      end

      def yarp_bool
        raise TypeError, "Cannot invoke yarp_bool on concrete integer type" unless @val.zero?

        @signed
      end

      def ==(other)
        @val == other
      end

      def to_i
        @val
      end
    end
  end
end
