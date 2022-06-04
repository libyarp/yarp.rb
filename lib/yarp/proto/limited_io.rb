# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: LimitedIO limits #read calls on a given io to a predefined
    # number of times.
    class LimitedIO
      EMPTY = [].freeze

      def initialize(io, limit)
        @io = io
        @limit = limit
        @read = 0
      end

      def read(size)
        return EMPTY if size.zero?

        new_size = size.clamp(0..(@limit - @read))
        raise EOFError if new_size != size && new_size.zero?

        data = @io.read(new_size)
        @read += new_size
        data
      end
    end
  end
end
