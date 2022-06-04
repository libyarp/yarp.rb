# frozen_string_literal: true

RSpec.describe Yarp::Proto::String do
  subject { described_class }

  it "encodes and decodes a string value" do
    val = "Hello, World!"
    buf = StringIO.new
    subject.encode(buf, val)
    expected = [0xa1, 0x1a, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    out = subject.decode(buf.read(1), buf)
    expect(out).to eq(val)
  end
end
