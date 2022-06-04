# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: Float implements an encoder and decoder for Yarp's Float values
    class Float
      class << self
        def encode32(into, value)
          return into.write("\x48") if value.zero?

          arr = [0x40, value]
          into.write(arr.pack("Ce"))
        end

        def encode64(into, value)
          return into.write("\x58") if value.zero?

          arr = [0x50, value]
          into.write(arr.pack("CE"))
        end

        def decode(header, io)
          header = header.getbyte(0)
          bits = (header & 0x10) == 0x10 ? 64 : 32
          is_zero = header & 0x8 == 0x8
          return 0.0 if is_zero

          io.read(bits / 8).unpack1(bits == 32 ? "e" : "E")
        end
      end
    end
  end
end
