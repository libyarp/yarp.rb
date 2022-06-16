# frozen_string_literal: true

require_relative "server/driver"
require_relative "server/executor"
require_relative "server/configuration"

module Yarp
  # Public: Server implements a Yarp server.
  class Server
    attr_reader :callbacks

    def initialize
      @callbacks = {
        before: [],
        after: []
      }
    end

    def before(callable = nil, &block)
      obj = callable || block
      if obj.arity != -1 && obj.arity != 2
        raise ArgumentError, "global callbacks must accepts two arguments (request, handler)"
      end

      @callbacks[:before] << obj
    end

    def after(callable = nil, &block)
      obj = callable || block
      if obj.arity != -1 && obj.arity != 2
        raise ArgumentError, "global callbacks must accepts two arguments (request, handler)"
      end

      @callbacks[:after] << obj
    end

    # Public: starts the server runloop.
    def run
      config = Yarp.configuration
      EventMachine.run do
        Signal.trap("INT")  { EventMachine.stop }
        Signal.trap("TERM") { EventMachine.stop }

        EventMachine.start_server(
          config.bind_address,
          config.bind_port,
          Executor,
          @callbacks.freeze
        )
      end
    end
  end
end
