# frozen_string_literal: true

RSpec.describe Yarp::Server::Configuration do
  subject { described_class.new }

  %i[
    tls_cert_chain_file
    tls_cert
    tls_private_key_file
    tls_private_key
    tls_private_key_password
    tls_cipher_list
    tls_ecdh_curve
    tls_dhparam
    tls_ssl_version
  ].each do |key|
    it "defines a #{key}" do
      expect(subject).to respond_to(key)
      expect(subject).to respond_to("#{key}=")
    end
  end
end
