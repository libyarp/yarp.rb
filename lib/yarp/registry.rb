# frozen_string_literal: true

module Yarp
  # Internal: Registry implements a simple registry for structures and methods.
  module Registry
    # Internal: Resets the resgistry to its initial state.
    def self.reset!
      @registry ||= {}
      @registry.clear
      @method_registry ||= {}
      @method_registry.clear
    end

    # Internal: Registers a given structure. In case a structure with the same
    # identifier has already been registered, the previous record is replaced
    # with the provided struct.
    def self.register(struct)
      struct.validate!
      @registry ||= {}
      @registry[struct.instance_variable_get(:@yarp_id)] = struct
    end

    # Internal: Gets a structure definition with a given ID.
    #
    # Returns either a Class, or nil.
    def self.get(id)
      @registry ||= {}
      @registry[id]
    end

    # Internal: Registers a given method under an id, class, and name.
    # Optionally defines types the method receives and returns, and whether the
    # method is supposed to stream responses.
    def self.register_method(id, klass, name, receives: nil, returns: nil, streams: false)
      @method_registry ||= {}
      @method_registry[id] = {
        class: klass,
        name: name,
        receives: receives,
        returns: returns,
        streams: streams
      }
    end

    # Internal: Returns a method registered with a given ID, or nil.
    def self.find_method(id)
      @method_registry ||= {}
      @method_registry[id]
    end
  end
end
