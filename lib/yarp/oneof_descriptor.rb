# frozen_string_literal: true

module Yarp
  # OneofDescriptor represents a descriptor for a oneof field. This descriptor
  # provides its own fields.
  class OneofDescriptor
    attr_reader :fields

    # Internal: Creates a new instance of this class
    def initialize
      @fields = []
      @known_names = []
      @known_indexes = []
    end

    # Internal: Defines a field under a given name and index
    #
    # name  - Name of the field being defined.
    # index - Index of the field being defined.
    #
    # Returns nothing. Raises an exception in case the name or index has already
    # been declared.
    def define(name, index)
      raise ArgumentError, "duplicated name #{name}" if @known_names.include? name
      raise ArgumentError, "duplicated index #{index}" if @known_indexes.include? index

      @known_names << name
      @known_indexes << index
    end

    # Public: Declares a primitive field with a given name, type, and index.
    # Refer to Yarp's documentation to a list of possible types.
    #
    # Returns nothing. Raises an exception in case the name or index has already
    # been declared.
    def primitive(name, type, index)
      define(name, index)
      fields << FieldDescriptor.primitive(name, type, index)
    end

    # Public: Declares a map/associative array/hash field with a given name,
    # index, key, and value types.
    # Refer to Yarp's documentation to a list of valid types for both keys and
    # values.
    #
    # Returns nothing. Raises an exception in case the name or index has already
    # been declared.
    def map(name, index, key:, value:)
      define(name, index)
      fields << FieldDescriptor.map(name, index, key, value)
    end

    # Public: Declares an array field with a given name, index, and type.
    #
    # Returns nothing. Raises an exception in case the name or index has already
    # been declared.
    def array(name, index, of:)
      define(name, index)
      fields << FieldDescriptor.array(name, of, index)
    end

    def oneof(*_args, **_kwargs)
      raise TypeError, "invalid nested oneof field"
    end
  end
end
