# frozen_string_literal: true

require_relative "server/driver"
require_relative "server/executor"
require_relative "server/configuration"

module Yarp
  # Public: Server implements a Yarp server.
  class Server
    # Public: starts the server runloop.
    def run
      config = Yarp.configuration
      EventMachine.run do
        Signal.trap("INT")  { EventMachine.stop }
        Signal.trap("TERM") { EventMachine.stop }

        EventMachine.start_server(
          config.bind_address,
          config.bind_port,
          Executor
        )
      end
    end
  end
end
