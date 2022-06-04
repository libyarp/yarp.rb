# frozen_string_literal: true

RSpec.describe Yarp::Proto::Float do
  subject { described_class }

  it "encodes and decodes a float32 value" do
    buf = StringIO.new
    subject.encode32(buf, Math::PI)
    expected = [0x40, 0xdb, 0x0f, 0x49, 0x40]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    val = subject.decode(buf.read(1), buf)
    expect(val).to be_within(0.0001).of(Math::PI)
  end

  it "encodes and decodes a float64 value" do
    buf = StringIO.new
    subject.encode64(buf, Math::PI)
    expected = [0x50, 0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x09, 0x40]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    val = subject.decode(buf.read(1), buf)
    expect(val).to be_within(0.0001).of(Math::PI)
  end
end
