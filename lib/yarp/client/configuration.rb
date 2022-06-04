# frozen_string_literal: true

module Yarp
  class Client
    # Public: Represents a set of configuration options for clients.
    # Using Configuration::instance allows to define settings for all clients.
    # To update configuration keys for each client, pass a list of key-value pairs
    # to the Client constructor.
    class Configuration
      attr_accessor :tls_cert, :tls_private_key, :tls_private_key_password,
                    :tls_cipher_list, :tls_ecdh_curve, :tls_dhparam,
                    :tls_cert_chain_file, :tls_ssl_version, :use_tls,
                    :connect_timeout_sec, :write_timeout_sec, :read_timeout_sec,
                    :resolve_timeout_sec, :prefer_ipv4, :prefer_ipv6

      def self.instance
        @instance ||= new.tap do |c|
          c.tls_cipher_list = "ALL:!ADH:!LOW:!EXP:!DES-CBC3-SHA:@STRENGTH"
          c.tls_ssl_version = %i[TLSv1 TLSv1_1 TLSv1_2]
          c.connect_timeout_sec = 30
          c.write_timeout_sec = 3
          c.read_timeout_sec = 60
        end
      end

      def pack_write_timeout
        pack_timeout(write_timeout_sec)
      end

      def pack_read_timeout
        pack_timeout(read_timeout_sec)
      end

      private

      def pack_timeout(timeout)
        secs = Integer(timeout)
        usecs = Integer((timeout - secs) * 1_000_000)
        [secs, usecs].pack("l_2")
      end
    end
  end
end
