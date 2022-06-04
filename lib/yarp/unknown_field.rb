# frozen_string_literal: true

module Yarp
  # Public: UnknownField represents a field that was present in a transaction,
  # but does not have a matching descriptor.
  class UnknownField
    attr_accessor :descriptor, :value

    def initialize(descriptor, value, index)
      @descriptor = descriptor
      @value = value
      @index = index
    end

    def has_descriptor?
      !descriptor.nil?
    end
  end
end
