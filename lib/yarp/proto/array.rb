# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: Array implements an encoder and decoder for Yarp's Array values
    class Array
      EMPTY_ARRAY = "\x60"

      def self.[](type)
        new(type)
      end

      def initialize(type)
        @type = type
      end

      private :initialize

      def encode(into, val)
        Proto.validate_array! val
        return into.write(EMPTY_ARRAY) if val.empty?

        data = StringIO.new
        val.each { |i| Yarp.encode(data, i, as: @type) }
        header = Scalar.encode(data.length)
        header.setbyte(0, header.getbyte(0) | 0x60)
        into.write(header)
        into.write(data.string)
      end

      def decode(header, io)
        data = []
        size = Scalar.decode(header, io)
        raise SizeTooLargeError if size >= SIZE_LIMIT

        r_io = LimitedIO.new(io, size)
        loop do
          data << Yarp::Proto.decode(r_io, as: @type)
        rescue EOFError
          break
        end
        data
      end
    end

    # Internal: UntypeArray implements a decoder for an Array with unknown
    # type. For this type, types are inferred on a best-effort manner, and may
    # not necessarily represent its original values.
    class UntypedArray
      def self.decode(header, io)
        data = []
        size = Scalar.decode(header, io)
        raise SizeTooLargeError if size >= SIZE_LIMIT

        r_io = LimitedIO.new(io, size)
        loop do
          data << Yarp::Proto.decode(r_io, as: :any)
        rescue EOFError
          break
        end
        data
      end
    end
  end
end
