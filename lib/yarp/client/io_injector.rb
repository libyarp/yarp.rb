# frozen_string_literal: true

module Yarp
  class Client
    # Internal: IOInjector abstracts an IO object and injects a predefined
    # amount of data, yielding it before resorting to reading the provided IO.
    class IOInjector
      def initialize(pre_data, io)
        @io = io
        @pre_data = pre_data
        @left = pre_data.length
      end

      def read(size)
        return @io.read(size) if @left.zero?
        return unless size <= @left

        ret = @pre_data[@pre_data.length - @left..]
        @left -= size
        ret
      end
    end
  end
end
