# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: String implements an encoder and decoder for Yarp's String
    # values
    class String
      class << self
        def encode(into, value)
          str = value.encode("utf-8")
          tmp = Scalar.encode(value.bytesize)
          tmp.setbyte(0, tmp.getbyte(0) | 0xA0)
          into.write(tmp)
          into.write(str)
        end

        def decode(header, io)
          size = Scalar.decode(header, io)
          io.read(size).force_encoding("utf-8")
        end
      end
    end
  end
end
