# frozen_string_literal: true

module Yarp
  class Server
    # Internal: Middleware represents a Yarp middleware. Middlewares are
    # executed in order before the request is serviced by a handler. In case
    # a middle returns an error, the error is relayed to the client, and the
    # response chain is halted.
    class Middleware
      def initialize(req)
        @request = req
      end

      def run; end
    end
  end
end
