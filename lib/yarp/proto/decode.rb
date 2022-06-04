# frozen_string_literal: true

module Yarp
  # Internal: Module Proto defines all types and helpers for handling Protocol
  # entities and byte streams.
  module Proto
    def self.decode(io, as:)
      return decode_any(io) if as == :any
      return decode_any_with_meta(io) if as == :any_meta

      header = io.read(1)

      case as
      when :uint8, :uint16, :uint32, :uint64,
           :int8, :int16, :int32, :int64
        Scalar.decode(header, io)
      when :bool
        Scalar.decode(header, io).yarp_bool
      when :float32, :float64
        Float.decode(header, io)
      when :string
        String.decode(header, io)
      when :array
        UntypedArray.decode(header, io)
      when :map
        Map.decode(header, io)
      when :oneof
        Oneof.decode(header, io)
      when :invalid
        raise InvalidTypeInStreamError, "invalid type in stream"
      end
    end

    def self.decode_any(io)
      header = io.read(1)
      header_type = detect_type(header.getbyte(0))
      case header_type
      when :void
        nil
      when :scalar
        Scalar.decode(header, io)
      when :float
        Float.decode(header, io)
      when :array
        UntypedArray.decode(header, io)
      when :struct
        EncodedStruct.decode(header, io)
      when :string
        String.decode(header, io)
      when :map
        Map.decode(header, io)
      when :oneof
        Oneof.decode(header, io)
      when :invalid
        raise InvalidTypeInStreamError, "invalid type in stream"
      end
    end

    def self.decode_any_with_meta(io)
      header = io.read(1)
      header_type = detect_type(header.getbyte(0))
      case header_type
      when :void
        nil
      when :scalar
        Scalar.decode(header, io)
      when :float
        Float.decode(header, io)
      when :array
        UntypedArray.decode(header, io)
      when :struct
        EncodedStruct.decode(header, io)
      when :string
        String.decode(header, io)
      when :map
        Map.decode(header, io)
      when :oneof
        Oneof.decode(header, io)
      when :invalid
        raise InvalidTypeInStreamError, "invalid type in stream"
      end
    end
  end
end
