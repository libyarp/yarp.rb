# frozen_string_literal: true

RSpec.describe Yarp::Proto::Oneof do
  subject { described_class }

  it "encodes and decodes a string value" do
    val = subject.new(45, "Hello, World!")
    buf = StringIO.new
    val.encode(buf)
    expected = [0xe1, 0x22, 0x21, 0x5a, 0xa1, 0x1a, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0x6f, 0x72, 0x6c,
                0x64, 0x21]
    expect(buf.string).to eq expected.pack("C*").force_encoding("UTF-8")
    buf.seek(0)
    out = subject.decode(buf.read(1), buf)
    expect(out.index).to eq 45
    expect(out.data).to eq "Hello, World!"
  end
end
