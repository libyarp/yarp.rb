# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: EncodedStruct implements an encoder and decoder for Yarp's
    # Structure values
    class EncodedStruct
      attr_accessor :id, :fields

      def self.encode(into, val)
        raise InvalidStructureError unless val.class.ancestors.include? Yarp::Structure

        fields = val.class.instance_variable_get(:@fields)
        indexes = fields.filter { |f| f.index.is_a? Integer }.map(&:index).sort
        buf = StringIO.new
        0.upto(indexes.last).each do |i|
          f = fields.find { |field| field.index == i }
          f.encode(buf, val)
        end
        header = Scalar.encode(buf.length + 8) # ID + Body
        header.setbyte(0, header.getbyte(0) | 0x80)
        into.write(header)
        into.write([val.class.instance_variable_get(:@yarp_id)].pack("Q<"))
        into.write(buf.string)
      end

      def self.decode(header, io)
        size = Scalar.decode(header, io)
        raise SizeTooLargeError if size >= Proto::SIZE_LIMIT

        r = LimitedIO.new(io, size)
        id = r.read(8).unpack1(">Q")
        f = []
        loop do
          f << Proto.decode(r, as: :any_meta)
        rescue EOFError
          break
        end
        new.tap do |i|
          i.id = id
          i.fields = f
        end
      end

      def specialize
        struct_class = Yarp::Registry.get(id)
        return false unless struct_class

        inst = struct_class.new
        r_unknown = lambda do |ft, val|
          inst.unknown_fields << UnknownField.new(ft, val, nil)
        end
        struct_fields = struct_class.instance_variable_get(:@fields)
        @fields.each_with_index do |v, i|
          ft = struct_fields.find { |f| f.index == i }
          if ft.nil?
            inst.unknown_fields << UnknownField.new(nil, v, i)
            next
          end

          next if ft.specialize_into(inst, v)

          r_unknown[ft, v]
        end
        inst
      end
    end
  end
end
