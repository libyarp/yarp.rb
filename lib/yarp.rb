# frozen_string_literal: true

require "stringio"
require "eventmachine"
require "logrb"
require "date"
require "openssl"
require "uri"

require_relative "yarp/version"
require_relative "yarp/proto"
require_relative "yarp/parser"
require_relative "yarp/oneof_descriptor"
require_relative "yarp/field_descriptor"
require_relative "yarp/unknown_field"
require_relative "yarp/registry"
require_relative "yarp/common_responses"
require_relative "yarp/responseable"
require_relative "yarp/service"
require_relative "yarp/structure"
require_relative "yarp/server"
require_relative "yarp/client"
require_relative "yarp/ext/time"

# Yarp provides abstractions for implementing Yarp Clients and Servers.
module Yarp
  class Error < StandardError; end
  class UnconvertibleValueError < Error; end
  class InvalidTypeInStreamError < Error; end
  class SizeTooLargeError < Error; end
  class MinFieldNotZeroError < Error; end
  class FieldGapError < Error; end
  class InvalidStructureError < Error; end
  class InvalidMetadataError < Error; end
  class UnknownFieldInitializationError < Error; end
  class CorruptStreamError < Error; end
  class NonStreamableResponseError < Error; end

  def self.encode(into, val, as: nil)
    Proto.encode(into, val, as: as)
  end

  # :warn, :exception, :none
  def self.handle_unknown_field_initialization_with=(method)
    @unknown_field_handler = method
  end

  def self.handle_unknown_field_initialization_with
    @unknown_field_handler || :warn
  end

  def self.configure
    inst = Yarp::Server::Configuration.instance
    return inst unless block_given?

    yield
    nil
  end

  def self.logger
    configure.logger
  end

  def self.configuration
    configure
  end
end
