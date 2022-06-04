# frozen_string_literal: true

module Yarp
  # Internal: Module Proto defines all types and helpers for handling Protocol
  # entities and byte streams.
  module Proto
  end
end

require_relative "proto/scalar" # Must come before Types
require_relative "proto/types"
require_relative "proto/array"
require_relative "proto/float"
require_relative "proto/string"
require_relative "proto/void"
require_relative "proto/map"
require_relative "proto/oneof"
require_relative "proto/encode"
require_relative "proto/decode"
require_relative "proto/encoded_struct"
require_relative "proto/limited_io"
require_relative "proto/wire"
