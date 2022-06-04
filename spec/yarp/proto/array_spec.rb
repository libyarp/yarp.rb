# frozen_string_literal: true

RSpec.describe Yarp::Proto::Array do
  it "encodes arrays of strings" do
    buf = StringIO.new
    items = %w[
      Coffee
      Caffé
      Covfefe
    ]
    Yarp::Proto::Array[:string].encode(buf, items)
    expected = [0x61, 0x32, 0xa1, 0xc, 0x43, 0x6f, 0x66, 0x66, 0x65, 0x65, 0xa1, 0xc, 0x43, 0x61, 0x66, 0x66, 0xc3,
                0xa9, 0xa1, 0xe, 0x43, 0x6f, 0x76, 0x66, 0x65, 0x66, 0x65]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    decoded = Yarp::Proto::Array[:string].decode(buf.read(1), buf)
    expect(decoded).to eq items
  end

  it "encodes arrays of ints" do
    buf = StringIO.new
    items = [0xC0, 0xFF, 0xEE]
    Yarp::Proto::Array[:uint8].encode(buf, items)
    expected = [0x61, 0xc, 0x23, 0x80, 0x23, 0xfe, 0x23, 0xdc]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    decoded = Yarp::Proto::Array[:uint8].decode(buf.read(1), buf)
    expect(decoded).to eq items
  end

  it "encodes arrays of floats" do
    buf = StringIO.new
    items = [
      0.1,
      0.2,
      0.3
    ]
    Yarp::Proto::Array[:float32].encode(buf, items)
    expected = [0x61, 0x1e, 0x40, 0xcd, 0xcc, 0xcc, 0x3d, 0x40, 0xcd, 0xcc, 0x4c, 0x3e, 0x40, 0x9a, 0x99, 0x99, 0x3e]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    decoded = Yarp::Proto::Array[:float32].decode(buf.read(1), buf)
    expect(decoded[0]).to be_within(0.0001).of(0.1)
    expect(decoded[1]).to be_within(0.0001).of(0.2)
    expect(decoded[2]).to be_within(0.0001).of(0.3)
  end
end
