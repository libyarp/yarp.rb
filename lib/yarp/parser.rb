# frozen_string_literal: true

module Yarp
  # Internal: Module Parser defines all mechanisms required for parsing
  # Yarp values, structures, and messages.
  module Parser
    # Internal: Derects and returns a new parser from a given byte, or
    # raises InvalidTypeInStreamError in case the value does not correspond to
    # a valid Yarp type.
    def self.detect_parser(byte)
      case Yarp::Proto.detect_type(byte)
      when :void
        nil
      when :scalar
        ScalarParser.new
      when :float
        FloatParser.new
      when :array
        ArrayParser.new
      when :struct
        EncodedStructParser.new
      when :string
        StringParser.new
      when :map
        MapParser.new
      when :oneof
        OneofParser.new
      else
        raise InvalidTypeInStreamError
      end
    end
  end
end

require_relative "parser/scalar_parser"
require_relative "parser/float_parser"
require_relative "parser/string_parser"
require_relative "parser/array_parser"
require_relative "parser/map_parser"
require_relative "parser/oneof_parser"
require_relative "parser/encoded_struct_parser"
require_relative "parser/request_parser"
require_relative "parser/response_parser"
require_relative "parser/error_parser"
