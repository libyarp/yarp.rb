# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: Void implements an encoder for Yarp's Void values
    class Void
      def self.encode(into)
        into.write("\x0")
      end
    end
  end
end
