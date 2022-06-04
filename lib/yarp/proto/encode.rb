# frozen_string_literal: true

module Yarp
  # Internal: Module Proto defines all types and helpers for handling Protocol
  # entities and byte streams.
  module Proto
    def self.encode(into, val, as: nil)
      if as.nil?
        encode_detect(into, val)
      else
        encode_as(into, val, as)
      end
    end

    def self.encode_detect(into, val)
      case val
      when ::Integer
        encode_as(into, val, :uint64)
      when ::Float
        encode_as(into, val, :float64)
      when ::String, ::Symbol
        encode_as(into, val, :string)
      when ::TrueClass, ::FalseClass
        encode_as(into, val, :bool)
      when ::NilClass
        encode_as(into, nil, :void)
      else
        return encode_as(into, val, :struct) if val.class.ancestors.include? Yarp::Structure

        raise ArgumentError, "Unexpected type #{val.class}"
      end
    end

    def self.encode_as(into, val, as)
      case as
      when :void
        Void.encode(into)
      when :uint8, :uint16, :uint32, :uint64
        Scalar.encode_integer(into, convert!(val, ::Integer), signed: false)
      when :int8, :int16, :int32, :int64
        Scalar.encode_integer(into, convert!(val, ::Integer), signed: true)
      when :float32
        Float.encode32(into, convert!(val, ::Float))
      when :float64
        Float.encode64(into, convert!(val, ::Float))
      when :bool
        if val.is_a? Scalar
          Scalar.encode_boolean(into, val.signed?)
        else
          Scalar.encode_boolean(into, !val.nil?)
        end
      when :string
        String.encode(into, convert!(val, ::String))
      when :struct
        EncodedStruct.encode(into, val)
      else
        return encode_as(into, val, :struct) if as.ancestors.include? Yarp::Structure

        raise ArgumentError, "Unexpected type #{as}"
      end
    end
  end
end
