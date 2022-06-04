# frozen_string_literal: true

RSpec.describe Yarp::Proto do
  it "encodes and decodes a request" do
    req = Yarp::Proto::Request.new(0x0, {
      "RequestID" => "Hello!"
    })
    buf = StringIO.new
    req.encode(buf)
    buf.rewind
    expected = [
      0x79, 0x79, 0x72, 0x21, 0x34, 0x20, 0xc1, 0x2e, 0x21, 0x16, 0xa1, 0x12,
      0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x49, 0x44, 0x21, 0x10, 0xa1,
      0xc, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x21
    ]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    dec = Yarp::Proto::Request.decode(buf)
    expect(dec.method_id).to eq 0x0
    expect(dec.headers).to eq req.headers
  end

  it "encodes and decodes a response" do
    resp = Yarp::Proto::Response.new({
      "Header" => "Value"
    }, true)
    buf = StringIO.new
    resp.encode(buf)
    buf.rewind
    expected = [
      0x79, 0x79, 0x52, 0xc1, 0x26, 0x21, 0x10, 0xa1, 0xc, 0x48, 0x65, 0x61,
      0x64, 0x65, 0x72, 0x21, 0xe, 0xa1, 0xa, 0x56, 0x61, 0x6c, 0x75, 0x65,
      0x30
    ]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    dec = Yarp::Proto::Response.decode(buf)
    expect(dec.headers).to eq resp.headers
    expect(dec.stream).to eq true
  end

  it "encodes and decodes an error" do
    err = Yarp::Proto::Error.new(
      Yarp::Proto::Error::INTERNAL_ERROR,
      { "Header" => "Value" },
      "Identifier",
      nil
    )

    buf = StringIO.new
    err.encode(buf)
    buf.rewind
    expected = [
      0x79, 0x79, 0x65, 0x20, 0xc1, 0x26, 0x21, 0x10, 0xa1, 0xc, 0x48, 0x65,
      0x61, 0x64, 0x65, 0x72, 0x21, 0xe, 0xa1, 0xa, 0x56, 0x61, 0x6c, 0x75,
      0x65, 0xa1, 0x14, 0x49, 0x64, 0x65, 0x6e, 0x74, 0x69, 0x66, 0x69, 0x65,
      0x72, 0xc0
    ]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    dec = Yarp::Proto::Error.decode(buf)
    expect(dec.kind).to eq err.kind
    expect(dec.headers).to eq err.headers
    expect(dec.identifier).to eq err.identifier
    expect(dec.user_data).to eq err.user_data
  end
end
