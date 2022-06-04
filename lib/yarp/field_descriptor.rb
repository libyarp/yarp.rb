# frozen_string_literal: true

module Yarp
  # Internal: FieldDescriptor represents a single field for a Yarp structure.
  class FieldDescriptor
    attr_accessor :index, :name, :kind

    # Primitive/Array/Struct
    attr_accessor :type

    # Primitive
    attr_accessor :optional

    # Map
    attr_accessor :key_type, :value_type

    # Oneof
    attr_accessor :descriptor

    # Public: Creates a new primitive field descriptor.
    #
    # name     - Name of the field being declared.
    # type     - The field's type. Refer to the Yarp documentation for further
    #            information.
    # index    - Index of the field being declared.
    # optional - Whether the field is optional; defaults to false.
    #
    # Returns a FieldDescriptor configured with the provided keys.
    def self.primitive(name, type, index, optional: false)
      new(index, :primitive).tap do |i|
        i.name = name
        i.optional = optional
        i.type = type
      end
    end

    # Public: Defines a new array/repeated field descriptor.
    #
    # name     - Name of the field being declared.
    # type     - The field's type. Refer to the Yarp documentation for further
    #            information.
    # index    - Index of the field being declared.
    #
    # Returns a FieldDescriptor configured with the provided keys.
    def self.array(name, type, index)
      new(index, :array).tap do |i|
        i.name = name
        i.type = type
      end
    end

    # Public: Defines a new hash/map/associative array field descriptor.
    #
    # name       - Name of the field being declared.
    # index      - Index of the field being declared.
    # key_type   - The field's key type. Refer to the Yarp documentation for
    #              further information.
    # value_type - The field's value type. Refer to the Yarp documentation for
    #              further information.
    #
    # Returns a FieldDescriptor configured with the provided keys.
    def self.map(name, index, key_type, value_type)
      new(index, :map).tap do |i|
        i.name = name
        i.key_type = key_type
        i.value_type = value_type
      end
    end

    # Public: Defines a new oneof field descriptor.
    #
    # index      - Index of the field being declared.
    # descriptor - An instance of OneofDescriptor to be associated with
    #              this descriptor
    #
    # Returns a FieldDescriptor configured with the provided keys.
    def self.oneof(index, descriptor)
      new(index, :oneof).tap { |i| i.descriptor = descriptor }
    end

    # Public: Creates a new structure field descriptor.
    #
    # name     - Name of the field being declared.
    # type     - The field's type. Refer to the Yarp documentation for further
    #            information.
    # index    - Index of the field being declared.
    # optional - Whether the field is optional; defaults to false.
    #
    # Returns a FieldDescriptor configured with the provided keys.
    def self.struct(name, type, index, optional: false)
      new(index, :struct).tap do |i|
        i.name = name
        i.optional = optional
        i.type = type
      end
    end

    # Internal: Initializes a new FieldDescriptor with a given index and kind
    def initialize(index, kind)
      @index = index
      @kind = kind
    end

    # Public: Returns whether the current descriptor is a oneof field.
    def oneof?
      kind == :oneof
    end

    # Internal: Encodes a value into a given buffer through the current
    # descriptor's configuration.
    def encode(into, val)
      v = oneof? ? nil : val.send(name.to_s)
      case kind
      when :primitive
        return encode(into, nil, as: :void) if optional && val.nil?
        raise TypeError, "Attempt to encode nil #{type} on non-optional field" if !optional && val.nil?

        Proto.encode(into, v, as: type)

      when :array
        Proto::Array[type].encode(into, v)

      when :map
        Proto::Map.new(key_type, value_type).encode(into, v)

      when :oneof
        f = descriptor.fields.sort_by(&:index).find { |i| val.send("has_#{i.name}?") }

        Proto::Oneof.new(f.index, val.send(f.name)).encode(into)
      when :struct
        return Proto.encode(into, nil, as: :void) if optional && v.nil?
        raise TypeError, "Attempt to encode nil #{type} on non-optional field" if !optional && v.nil?

        Proto::EncodedStruct.encode(into, v)
      end
    end

    # Internal: Attempts to specialize a given value into a given instance.
    #
    # inst - Instance to receive the value.
    # v    - Value to be specialized into the instance.
    #
    # Returns a boolean indicating whether the specialization operation
    # succeeded.
    def specialize_into(inst, v)
      case kind
      when :primitive
        specialize_primitive(inst, v)

      when :array
        specialize_array(inst, v)

      when :map
        specialize_map(inst, v)

      when :oneof
        specialize_oneof(inst, v)

      when :struct
        specialize_struct(inst, v)

      else
        false
      end
    end

    # Internal: Attempts to specialize a given primitive value into a given
    # instance.
    #
    # inst - Instance to receive the value.
    # v    - Value to be specialized into the instance.
    #
    # Returns a boolean indicating whether the specialization operation
    # succeeded.
    def specialize_primitive(inst, v)
      if optional && v.nil?
        inst.send("#{name}=", nil)
        return true
      end

      case type
      when :int8, :int16, :int32, :int64
        return false unless v.is_a? Proto::Scalar
        return false unless v.signed?

        inst.send("#{name}=", v.to_i)

      when :uint8, :uint16, :uint32, :uint64
        return false unless v.is_a? Proto::Scalar
        return false if v.signed?

        inst.send("#{name}=", v)

      when :string
        return false unless v.is_a? ::String

        inst.send("#{name}=", v)

      when :bool
        return false unless v.is_a? Proto::Scalar
        return false unless v.zero?

        inst.send("#{name}=", v.signed?)

      when :float32, :float64
        return false unless v.is_a? ::Float

        inst.send("#{name}=", v)

      else
        return false
      end

      true
    end

    # Internal: Attempts to specialize a given array value into a given
    # instance.
    #
    # inst - Instance to receive the value.
    # v    - Value to be specialized into the instance.
    #
    # Returns a boolean indicating whether the specialization operation
    # succeeded.
    def specialize_array(inst, v)
      return false unless v.is_a? ::Array

      begin
        inst.send("#{name}=", v.map { |i| Proto.convert!(i, type) })
        true
      rescue Yarp::Error
        false
      end
    end

    # Internal: Attempts to specialize a given map value into a given instance.
    #
    # inst - Instance to receive the value.
    # v    - Value to be specialized into the instance.
    #
    # Returns a boolean indicating whether the specialization operation
    # succeeded.
    def specialize_map(inst, v)
      if optional && v.nil?
        inst.send("#{name}=", nil)
        return true
      end
      return false unless v.is_a? ::Hash

      begin
        v = v.to_h do |key, val|
          [Proto.convert!(key, key_type), Proto.convert!(val, value_type)]
        end
        inst.send("#{name}=", v)
        true
      rescue Yarp::Error
        false
      end
    end

    # Internal: Attempts to specialize a given oneof value into a given
    # instance.
    #
    # inst - Instance to receive the value.
    # v    - Value to be specialized into the instance.
    #
    # Returns a boolean indicating whether the specialization operation
    # succeeded.
    def specialize_oneof(inst, v)
      return false unless v.is_a? Proto::Oneof

      f = descriptor.fields.find { |i| i.index == v.index }
      begin
        inst.send("#{f.name}=", Proto.convert!(v.data, f.type))
        true
      rescue Yarp::Error
        false
      end
    end

    # Internal: Attempts to specialize a given struct value into a given
    # instance.
    #
    # inst - Instance to receive the value.
    # v    - Value to be specialized into the instance.
    #
    # Returns a boolean indicating whether the specialization operation
    # succeeded.
    def specialize_struct(inst, v)
      if optional && v.nil?
        inst.send("#{name}=", nil)
        return true
      end
      return false unless v.is_a? Proto::EncodedStruct

      begin
        inst.send("#{name}=", Proto.convert!(v, type))
        true
      rescue Yarp::Error
        false
      end
    end
  end
end
