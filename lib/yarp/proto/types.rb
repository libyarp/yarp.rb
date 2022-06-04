# frozen_string_literal: true

module Yarp
  # Internal: Module Proto defines all types and helpers for handling Protocol
  # entities and byte streams.
  module Proto
    SIZE_LIMIT = 2e+9

    TYPES = {
      0x0 => :void,
      0x1 => :scalar,
      0x2 => :float,
      0x3 => :array,
      0x4 => :struct,
      0x5 => :string,
      0x6 => :map,
      0x7 => :oneof
    }.freeze

    VALID_HASH_KEYS = [
      ::String,
      ::Integer,
      ::Float
    ].freeze

    DIRECTLY_ENCODABLE_TYPES = [
      ::String, ::Float, ::Integer, ::TrueClass, ::FalseClass
    ].freeze

    CONVERTIBLE_TYPES = {
      [::Float, ::String] => :to_s,
      [::Integer, ::String] => :to_s,
      [::Float, ::Integer] => :to_i,
      [::Integer, ::Float] => :to_f,
      [::Symbol, ::String] => :to_s,
      [Scalar, :bool] => :yarp_bool
    }.freeze

    SOFT_TO_TYPE = {
      uint8: ::Integer,
      uint16: ::Integer,
      uint32: ::Integer,
      uint64: ::Integer,
      int8: ::Integer,
      int16: ::Integer,
      int32: ::Integer,
      int64: ::Integer,
      float32: ::Float,
      float64: ::Float,
      bool: Scalar,
      string: ::String
    }.freeze

    def self.detect_type(byte)
      TYPES.fetch(byte >> 5, :invalid)
    end

    def self.valid_hash_key_type?(type)
      VALID_HASH_KEYS.include? type
    end

    def self.can_encode?(value)
      type = value.class
      return true if DIRECTLY_ENCODABLE_TYPES.include? type

      case type
      when ::Hash
        validate_hash! value
      when ::Array
        validate_array! value
      else
        can_encode_object? value
      end
    end

    def self.validate_hash!(value)
      return false unless value.is_a? ::Hash
      return true if value.empty?

      # Ensure keys consistency
      return false unless consistent_array_type? value.keys
      return false unless valid_hash_key_type? value.keys.first.class

      # Ensure values consistency
      return false unless consistent_array_type? value.values

      can_encode? value.values.first
    end

    def self.consistent_array_type?(value)
      type = value.first.class
      value.all? { |v| v.instance_of?(type) }
    end

    def self.validate_array!(value)
      return if value.nil?
      raise ArgumentError, "Expected array, found #{value.class} instead" unless value.is_a? ::Array
      return if value.empty?
      raise ArgumentError, "Only homogeneous arrays are supported" unless consistent_array_type? value
      return if can_encode? value.first

      raise ArgumentError, "Cannot encode array with unsupported type #{value.first.class}"
    end

    def self.can_encode_object?(value)
      value.class.ancestors.include? Yarp::Structure
    end

    def self.can_convert?(from, to)
      from == to || CONVERTIBLE_TYPES.key?([from, to])
    end

    def self.convert!(val, target_type)
      return val.yarp_bool if val.is_a?(Proto::Scalar) && target_type == :bool

      return val if !target_type.is_a?(::Symbol) && val.is_a?(target_type)
      if target_type.is_a?(::Symbol) && SOFT_TO_TYPE.key?(target_type) && val.is_a?(SOFT_TO_TYPE[target_type])
        return val
      end

      vclass = val.class
      return val.send(CONVERTIBLE_TYPES[[vclass, target_type]]) if can_convert?(vclass, target_type)

      if val.is_a?(::Hash) || (val.is_a?(::Array) && target_type.ancestors.include?(Yarp::Structure))
        return target_type.new(**val) if val.is_a?(::Hash)

        return target_type.new(*val)
      end

      if val.is_a?(Proto::EncodedStruct) && target_type.ancestors.include?(Yarp::Structure)
        ret = val.specialize
        return ret if ret.is_a?(target_type)
      end

      if val.is_a?(Proto::Scalar) && target_type.is_a?(::Symbol) && SOFT_TO_TYPE[target_type] == ::Integer
        return val.to_i
      end

      return Scalar.new(true, 0) if val.is_a?(TrueClass) && target_type == Scalar
      return Scalar.new(false, 0) if val.is_a?(FalseClass) && target_type == Scalar

      raise UnconvertibleValueError, "cannot convert #{val.inspect} (#{val.class.name}) to #{target_type.name}"
    end
  end
end
