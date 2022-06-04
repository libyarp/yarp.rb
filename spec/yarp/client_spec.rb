# frozen_string_literal: true

RSpec.describe Yarp::Client do
  subject { described_class.new("tcp://localhost") }

  it "rejects invalid addresses" do
    expect { described_class.new("https://vito.io") }.to raise_error(ArgumentError)
  end

  it "reuses global configuration" do
    inst = described_class.configure
    expect(inst).to be described_class.configure
  end

  context "emulated" do
    it "raises received errors" do
      c_socket, s_socket = UNIXSocket.pair
      err = Yarp::Proto::Error.generic("boom!")
      err.encode(s_socket)

      expect(subject).to receive(:connect).and_return(c_socket)
      begin
        subject.send(:exec, 0x01, "hello")
      rescue Yarp::Proto::Error => e
        expect(e).to be_managed_error
        expect(e.identifier).to eq "boom!"
      end
    end

    it "detects corrupt streams" do
      c_socket, s_socket = UNIXSocket.pair
      s_socket.write("yay")

      expect(subject).to receive(:connect).and_return(c_socket)
      expect { subject.send(:exec, 0x01, "hello") }.to raise_error(Yarp::CorruptStreamError)
    end

    it "returns single encoded value" do
      c_socket, s_socket = UNIXSocket.pair
      r = Yarp::Proto::Response.new({}, false)
      r.encode(s_socket)
      Yarp::Proto.encode(s_socket, "Hello!")

      expect(subject).to receive(:connect).and_return(c_socket)
      headers, body = subject.send(:exec, 0x01, "hello")
      expect(headers).to be_empty
      expect(body).to eq "Hello!"
    end

    it "returns all items" do
      c_socket, s_socket = UNIXSocket.pair
      r = Yarp::Proto::Response.new({}, true)
      r.encode(s_socket)
      10.times { |i| Yarp::Proto.encode(s_socket, i) }
      s_socket.close_write

      expect(subject).to receive(:connect).and_return(c_socket)
      headers, body = subject.send(:exec, 0x01, "hello")
      expect(headers).to be_empty
      expect(body.length).to eq 10
    end

    it "yields all items" do
      c_socket, s_socket = UNIXSocket.pair
      r = Yarp::Proto::Response.new({}, true)
      r.encode(s_socket)
      10.times { |i| Yarp::Proto.encode(s_socket, i) }
      s_socket.close_write

      expect(subject).to receive(:connect).and_return(c_socket)
      called = 0
      subject.send(:exec, 0x01, "hello") do |_i|
        called += 1
      end
      expect(called).to eq 10
    end

    it "yields all items with headers" do
      c_socket, s_socket = UNIXSocket.pair
      r = Yarp::Proto::Response.new({ Ok: "true" }, true)
      r.encode(s_socket)
      10.times { |i| Yarp::Proto.encode(s_socket, i) }
      s_socket.close_write

      expect(subject).to receive(:connect).and_return(c_socket)
      called = 0
      subject.send(:exec, 0x01, "hello") do |_i, h|
        called += 1
        expect(h["Ok"]).to eq "true"
      end
      expect(called).to eq 10
    end
  end

  context "tcp" do
    it "returns single encoded value" do
      address = spin_tcp_server do |sock|
        Yarp::Proto::Response.new({}, false).encode(sock)
        Yarp::Proto.encode(sock, "Hello!")
      end
      client = described_class.new(address)
      headers, body = client.send(:exec, 0x01, "hello")
      expect(headers).to be_empty
      expect(body).to eq "Hello!"
    end
  end

  context "unix" do
    it "returns single encoded value" do
      address = spin_unix_socket_server do |sock|
        Yarp::Proto::Response.new({}, false).encode(sock)
        Yarp::Proto.encode(sock, "Hello!")
      end
      client = described_class.new(address)
      headers, body = client.send(:exec, 0x01, "hello")
      expect(headers).to be_empty
      expect(body).to eq "Hello!"
    end
  end

  context "tls" do
    it "returns single encoded value" do
      address = spin_tcp_server(tls: "trusted") do |sock|
        Yarp::Proto::Response.new({}, false).encode(sock)
        Yarp::Proto.encode(sock, "Hello!")
      end

      client = described_class.new(address, use_tls: true, tls_cert_chain_file: File.read(tls_ca_file))
      headers, body = client.send(:exec, 0x01, "hello")
      expect(headers).to be_empty
      expect(body).to eq "Hello!"
    end
  end
end
