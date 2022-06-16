# frozen_string_literal: true

RSpec.describe Yarp::Server::Driver do
  let(:conn) { double(:connection) }
  subject { described_class.new(conn, { after: [], before: [] }.freeze) }

  it "initializes the request" do
    expect(subject.state).to eq :new
  end

  it "parses and set request" do
    discard_all_data(conn)

    req = Yarp::Proto::Request.new(0x102030, {
      "Header-Key" => "Header-Value"
    })
    buf = StringIO.new
    req.encode(buf)

    # This is required so we get a :received_headers instead of an :errored in
    # one of our assertions. Without registering, the driver will fallback into
    # a "unimplemented method" error.
    register_dummy_method(0x102030)

    subject.dispatch_byte(buf.string[0])
    expect(subject.state).to eq :waiting_headers
    buf.string[1..].each_byte { |b| subject.dispatch_byte(b) }
    expect(subject.state).to eq :received_headers
    expect(subject.request.method_id).to eq req.method_id
    expect(subject.request.headers).to eq req.headers
  end

  it "parses a body and delegate to the correct method" do
    discard_all_data(conn)
    expect(subject).not_to receive(:handle_error)

    req = Yarp::Proto::Request.new(0x102030, {
      "Header-Key" => "Header-Value"
    })
    buf = StringIO.new
    req.encode(buf)

    cls = register_struct do
      yarp_meta id: 0x01, package: "test", name: "foo"

      primitive :id, :int64, 0
      primitive :name, :string, 1
    end

    received_headers = nil
    received_arg = nil
    register_dummy_method(0x102030, receives: cls) do |arg|
      received_headers = headers
      received_arg = arg
    end

    stream(buf, into: subject)

    inst = cls.new(id: 27, name: "Paul Appleseed")
    buf = StringIO.new
    Yarp::Proto::EncodedStruct.encode(buf, inst)
    stream(buf.string[0], into: subject)
    expect(subject.state).to eq :receiving_body
    stream(buf.string[1..], into: subject)
    expect(subject.state).to eq :wrote_response

    expect(received_headers).to eq req.headers
    expect(received_arg).to be_a cls
    expect(received_arg.id).to eq 27
    expect(received_arg.name).to eq "Paul Appleseed"
  end

  it "parses body and returns data" do
    retain_data(conn)
    expect(subject).not_to receive(:handle_error)

    req = Yarp::Proto::Request.new(0x102030, {
      "Header-Key" => "Header-Value"
    })
    buf = StringIO.new
    req.encode(buf)

    cls = register_struct do
      yarp_meta id: 0x01, package: "test", name: "foo"

      primitive :id, :int64, 0
      primitive :name, :string, 1
    end

    register_dummy_method(0x102030, receives: cls, returns: cls) do |_arg|
      add_header foo: "bar"
      { id: 39, name: "Who" }
    end

    stream(buf, into: subject)
    inst = cls.new(id: 27, name: "Paul Appleseed")
    buf = StringIO.new
    Yarp::Proto::EncodedStruct.encode(buf, inst)
    stream(buf.string[0], into: subject)
    expect(subject.state).to eq :receiving_body
    stream(buf.string[1..], into: subject)
    expect(subject.state).to eq :wrote_response
    retained_data.rewind
    h = Yarp::Proto::Response.decode(retained_data)
    r = Yarp::Proto.decode_any(retained_data).specialize
    expect(h.headers["foo"]).to eq "bar"
    expect(r.id).to eq 39
    expect(r.name).to eq "Who"
  end

  it "writes streams" do
    retain_data(conn)
    expect(subject).not_to receive(:handle_error)

    req = Yarp::Proto::Request.new(0x102030, {
      "Header-Key" => "Header-Value"
    })
    buf = StringIO.new
    req.encode(buf)

    cls = register_struct do
      yarp_meta id: 0x01, package: "test", name: "foo"

      primitive :id, :int64, 0
      primitive :name, :string, 1
    end

    register_dummy_method(0x102030, receives: cls, returns: cls, streams: true) do |_arg|
      add_header foo: "bar"
      [
        { id: 39, name: "Who" },
        { id: 40, name: "Are" },
        { id: 41, name: "You" }
      ].each { |i| stream i }
    end

    stream(buf, into: subject)
    inst = cls.new(id: 27, name: "Paul Appleseed")
    buf = StringIO.new
    Yarp::Proto::EncodedStruct.encode(buf, inst)
    stream(buf.string[0], into: subject)
    expect(subject.state).to eq :receiving_body
    stream(buf.string[1..], into: subject)
    expect(subject.state).to eq :wrote_response
    retained_data.rewind
    h = Yarp::Proto::Response.decode(retained_data)
    expect(h.headers["foo"]).to eq "bar"

    r = Yarp::Proto.decode_any(retained_data).specialize
    expect(r.id).to eq 39
    expect(r.name).to eq "Who"

    r = Yarp::Proto.decode_any(retained_data).specialize
    expect(r.id).to eq 40
    expect(r.name).to eq "Are"

    r = Yarp::Proto.decode_any(retained_data).specialize
    expect(r.id).to eq 41
    expect(r.name).to eq "You"
  end

  it "drops the connection in case reading headers detects a corrupt stream" do
    expect(conn).to receive(:close_connection)
    stream("000", into: subject)
  end

  it "handles service initialisation errors" do
    retain_data(conn)
    srv = double(:borked_service)
    allow(Yarp::Registry).to receive(:find_method).with(0x01).and_return({
      class: srv,
      name: :dummy_caller
    })
    allow(srv).to receive(:new) { raise "Boom!" }
    req = Yarp::Proto::Request.new(0x01, nil)
    buf = StringIO.new
    req.encode(buf)

    stream(buf, into: subject)
    parser = Yarp::Parser::ErrorParser.new
    ok, err = stream(retained_data, into: parser, through: :feed)
    expect(ok).to eq true
    expect(err).to be_internal_error
  end

  it "initialises responses from arays" do
    retain_data(conn)
    expect(subject).not_to receive(:handle_error)

    req = Yarp::Proto::Request.new(0x102030, {
      "Header-Key" => "Header-Value"
    })
    buf = StringIO.new
    req.encode(buf)

    cls = register_struct do
      yarp_meta id: 0x01, package: "test", name: "foo"

      primitive :id, :int64, 0
      primitive :name, :string, 1
    end

    register_dummy_method(0x102030, receives: cls, returns: cls) do |_arg|
      add_header foo: "bar"
      [39, "Who"]
    end

    stream(buf, into: subject)
    inst = cls.new(id: 27, name: "Paul Appleseed")
    buf = StringIO.new
    Yarp::Proto::EncodedStruct.encode(buf, inst)
    stream(buf.string[0], into: subject)
    expect(subject.state).to eq :receiving_body
    stream(buf.string[1..], into: subject)
    expect(subject.state).to eq :wrote_response
    retained_data.rewind
    h = Yarp::Proto::Response.decode(retained_data)
    r = Yarp::Proto.decode_any(retained_data).specialize
    expect(h.headers["foo"]).to eq "bar"
    expect(r.id).to eq 39
    expect(r.name).to eq "Who"
  end

  context "with global callbacks" do
    let(:conn) { double(:connection) }
    let(:calls) { [] }
    subject do
      described_class.new(conn, {
        before: [proc { |_req, _hand| calls << :before }],
        after: [proc { |_req, _hand|  calls << :after }]
      }.freeze)
    end

    it "invokes all callbacks" do
      discard_all_data(conn)
      expect(subject).not_to receive(:handle_error)

      req = Yarp::Proto::Request.new(0x102030, nil) { |*_args| }
      buf = StringIO.new
      req.encode(buf)

      cls = register_struct do
        yarp_meta id: 0x01, package: "test", name: "foo"

        primitive :id, :int64, 0
        primitive :name, :string, 1
      end

      register_dummy_method(0x102030, receives: cls)

      stream(buf, into: subject)
      inst = cls.new(id: 27, name: "Paul Appleseed")
      buf = StringIO.new
      Yarp::Proto::EncodedStruct.encode(buf, inst)
      stream(buf, into: subject)

      expect(calls).to eq %i[before after]
    end
  end

  context "with failing global before callback" do
    let(:conn) { double(:connection) }
    let(:calls) { [] }
    subject do
      described_class.new(conn, {
        before: [proc { |_req, _hand| raise "boom!" }],
        after: [proc { |_req, _hand|  calls << :after }]
      }.freeze)
    end

    it "stops call chain" do
      discard_all_data(conn)
      expect(subject).to receive(:handle_error)
      expect(subject).not_to receive(:invoke_handler)

      req = Yarp::Proto::Request.new(0x102030, nil) { |*_args| }
      buf = StringIO.new
      req.encode(buf)

      cls = register_struct do
        yarp_meta id: 0x01, package: "test", name: "foo"

        primitive :id, :int64, 0
        primitive :name, :string, 1
      end

      register_dummy_method(0x102030, receives: cls)

      stream(buf, into: subject)
      inst = cls.new(id: 27, name: "Paul Appleseed")
      buf = StringIO.new
      Yarp::Proto::EncodedStruct.encode(buf, inst)
      stream(buf, into: subject)

      expect(calls).to be_empty
    end
  end

  context "with class callbacks" do
    let(:conn) { double(:connection) }
    let(:calls) { [] }
    subject do
      described_class.new(conn, {
        before: [proc { |_req, _hand| calls << :before_global }],
        after: [proc { |_req, _hand|  calls << :after_global }]
      }.freeze)
    end

    it "invokes all callbacks" do
      discard_all_data(conn)
      expect(subject).not_to receive(:handle_error)

      req = Yarp::Proto::Request.new(0x102030, nil) { |*_args| }
      buf = StringIO.new
      req.encode(buf)

      cls = register_struct do
        yarp_meta id: 0x01, package: "test", name: "foo"

        primitive :id, :int64, 0
        primitive :name, :string, 1
      end

      c = calls

      setup = proc do
        before_any { |_| c << :before_any }
        after_any { |_| c << :after_any }
        before(:dummy_caller) { c << :before }
        after(:dummy_caller) { c << :after }
      end

      register_dummy_method(0x102030,
                            receives: cls,
                            class_setup: setup)

      stream(buf, into: subject)
      inst = cls.new(id: 27, name: "Paul Appleseed")
      buf = StringIO.new
      Yarp::Proto::EncodedStruct.encode(buf, inst)
      stream(buf, into: subject)

      expect(calls).to eq %i[before_global before_any before after after_any after_global]
    end

    it "invokes symbol-based callbacks" do
      discard_all_data(conn)
      expect(subject).not_to receive(:handle_error)

      req = Yarp::Proto::Request.new(0x102030, nil) { |*_args| }
      buf = StringIO.new
      req.encode(buf)

      cls = register_struct do
        yarp_meta id: 0x01, package: "test", name: "foo"

        primitive :id, :int64, 0
        primitive :name, :string, 1
      end

      setup = proc do
        before_any(:be_an)
        after_any(:af_an)
        before(:dummy_caller, :be_du)
        after(:dummy_caller, :af_du)

        def be_du
          @calls ||= []
          @calls << :before
        end

        def af_du
          @calls ||= []
          @calls << :after
        end

        def be_an(_meth)
          @calls ||= []
          @calls << :before_any
        end

        def af_an(_meth)
          @calls ||= []
          @calls << :after_any
        end
      end

      register_dummy_method(0x102030,
                            receives: cls,
                            class_setup: setup)

      stream(buf, into: subject)
      inst = cls.new(id: 27, name: "Paul Appleseed")
      buf = StringIO.new
      Yarp::Proto::EncodedStruct.encode(buf, inst)
      stream(buf, into: subject)

      handler = subject.instance_variable_get(:@handler)
      expect(handler.instance_variable_get(:@calls)).to eq %i[before_any before after after_any]
    end
  end
end
