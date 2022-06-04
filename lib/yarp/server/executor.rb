# frozen_string_literal: true

module Yarp
  class Server
    # Internal: Executor abstracts EventMachine::Connection, and delegates
    # events to a Driver instance.
    class Executor < EM::Connection
      def post_init
        @driver = Driver.new(self)
        start_tls(**::Yarp.configuration.tls_configuration) if ::Yarp.configuration.enable_tls
      end

      def receive_data(data)
        data.each_byte { |byte| @driver.dispatch_byte(byte) }
      end

      def unbind
        @driver.notify_unbind
      end
    end
  end
end
