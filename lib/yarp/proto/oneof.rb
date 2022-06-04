# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: Oneof implements an encoder and decoder for Yarp's Oneof values
    class Oneof
      attr_reader :index, :data

      def initialize(index, data)
        @index = index
        # TODO: Can we encode data?
        @data = data
      end

      def encode(into)
        buf = StringIO.new
        Proto.encode(buf, @data)
        idx = Scalar.encode(@index)
        head = Scalar.encode(idx.length + buf.length).tap do |v|
          v.setbyte(0, v.getbyte(0) | 0xE0)
        end
        into.write(head)
        Scalar.encode_integer(into, @index, signed: false)
        into.write(buf.string)
      end

      def self.decode(header, io)
        size = Scalar.decode(header, io)
        return nil if size.zero?
        raise SizeTooLargeError if size >= Proto::SIZE_LIMIT

        reader = LimitedIO.new(io, size)
        idx = Scalar.decode(reader.read(1), reader)
        value = Proto.decode(reader, as: :any)
        new(idx, value)
      end
    end
  end
end
