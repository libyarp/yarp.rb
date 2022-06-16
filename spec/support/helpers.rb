# frozen_string_literal: true

module Helpers
  class ParseHelper
    def initialize(spec, buffer)
      @spec = spec
      @buffer = buffer
    end

    def with(parser)
      @parser = parser
      self
    end

    def matching
      do_loop
      yield @result
    end

    def do_loop
      done = false
      result = nil
      i = 0
      @buffer.string.each_byte do |b|
        @spec.send(:fail, "parser returned too early (#{i} iterations)") if done
        done, result = @parser.feed(b)
        i += 1
      end
      @spec.send(:fail, "parser did not return past loop (#{i} iterations)") unless done
      @result = result
    end

    def emitting(val)
      do_loop
      @spec.expect(@result).to @spec.eq val
    end
  end

  def parse(buffer)
    ParseHelper.new(self, buffer)
  end

  def discard_all_data(conn, dump: false)
    allow(conn).to receive(:send_data).with(anything) do |data|
      next unless dump

      puts "send_data received payload:"
      puts Hexdump.dump(data)
      puts "------ 8< ------"
    end
    allow(conn).to receive(:close_connection_after_writing)
    allow(conn).to receive(:close_connection)
  end

  def retain_data(conn)
    @retained_data ||= StringIO.new
    d = @retained_data
    allow(conn).to receive(:send_data).with(anything) { |data| d.write(data) }
    allow(conn).to receive(:close_connection_after_writing)
    allow(conn).to receive(:close_connection)
  end

  def retained_data
    @retained_data ||= StringIO.new
    @retained_data
  end

  def register_dummy_method(id, receives: nil, returns: nil, streams: false, class_setup: nil, &block)
    klass = Class.new do
      include Yarp::Service
    end
    block ||= ->(_arg) {}
    klass.class_eval do
      define_method(:dummy_caller) do |*args|
        instance_exec(*args, &block)
      end
    end

    klass.class_eval(&class_setup) unless class_setup.nil?

    allow(Yarp::Registry).to receive(:find_method).with(id).and_return({
      class: klass,
      name: :dummy_caller,
      receives: receives,
      returns: returns,
      streams: streams
    })
  end

  def register_struct(&block)
    Class.new(Yarp::Structure, &block)
  end

  def stream(data, into:, through: :dispatch_byte)
    data = data.string if data.is_a? StringIO
    last_value = nil
    data.each_byte { |b| last_value = into.send(through, b) }
    last_value
  end

  def configure_tls_server(kind, srv)
    opts = tls_opts(kind)
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.key = OpenSSL::PKey::RSA.new(opts[:tls_private_key])
    ctx.cert = OpenSSL::X509::Certificate.new(opts[:tls_cert])

    OpenSSL::SSL::SSLServer.new(srv, ctx)
  end

  def spin_tcp_server(tls: nil, &block)
    port = 0
    Socket.new(:INET, :STREAM, 0).tap do |socket|
      socket.bind(Addrinfo.tcp("127.0.0.1", 0))
      port = socket.local_address.ip_port
      socket.listen(5)
      Thread.new do
        socket = configure_tls_server(tls, socket) unless tls.nil?
        begin
          client_socket, _client_addrinfo = socket.accept
        rescue IO::WaitReadable, Errno::EINTR
          socket.wait_readable
          retry
        end
        block[client_socket]
        socket.close
      end
    end
    "tcp://127.0.0.1:#{port}"
  end

  def spin_unix_socket_server(&block)
    tmp = Tempfile.new
    target = tmp.path
    tmp.unlink
    UNIXServer.new(target).tap do |s|
      Thread.new do
        socket = s.accept
        block[socket]
        socket.close
        File.unlink(target)
      end
    end
    "unix://#{target}"
  end

  def tls_opts(prefix)
    tls_cert = File.join(cert_path, "#{prefix}-cert.crt")
    tls_key  = File.join(cert_path, "#{prefix}-cert.key")

    {
      tls_cert: File.read(tls_cert),
      tls_private_key: File.read(tls_key)
    }
  end

  def tls_ca_file
    File.join(cert_path, "trusted-ca.crt")
  end

  def cert_path
    File.expand_path("tls", __dir__)
  end
end
