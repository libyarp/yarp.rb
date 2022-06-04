# frozen_string_literal: true

module Yarp
  class Server
    # Configuration defines options that affect how the server handles requests
    class Configuration
      TLS_OPTS = {
        cert_chain_file: :cert_chain_file,
        cert: :cert,
        private_key_file: :private_key_file,
        private_key: :private_key,
        private_key_pass: :private_key_password,
        cipher_list: :cipher_list,
        ecdh_curve: :ecdh_curve,
        dhparam: :dhparam,
        ssl_version: :ssl_version
      }.freeze

      attr_accessor :bind_address, :bind_port, :enable_tls, :tls_cert,
                    :tls_private_key, :tls_private_key_file,
                    :tls_private_key_password, :tls_cipher_list,
                    :tls_ecdh_curve, :tls_dhparam, :tls_version,
                    :tls_cert_chain_file, :tls_ssl_version
      attr_writer :logger

      # Determines the log verbosity level. Valid options are:
      # - :debug
      # - :info (default)
      # - :warn
      # - :fatal
      # - :error
      attr_reader :log_level

      def initialize
        @bind_address = "127.0.0.1"
        @bind_port = 9753
        @log_level = :info
      end

      def tls_configuration
        return @tls_configuration unless @tls_configuration.nil?

        @tls_configuration = TLS_OPTS
                             .map { |k, v| [k, send("tls_#{v}")] }
                             .compact
                             .to_h
      end

      def logger
        @logger ||= Logrb.new($stdout, level: @log_level)
      end

      def log_level=(level)
        @log_level = level
        logger.level = level
      end

      def self.instance
        @instance ||= new
      end
    end
  end
end
