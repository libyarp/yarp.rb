# frozen_string_literal: true

RSpec.describe Yarp::Proto::Map do
  subject { described_class }

  it "encodes and decodes a map value" do
    val = {
      "a" => 1,
      "b" => 2,
      "c" => 3,
      "d" => 4
    }

    buf = StringIO.new
    subject.new(:string, :uint8).encode(buf, val)
    buf.seek(0)
    out = subject.decode(buf.read(1), buf)
    expect(out).to eq(val)
  end

  it "encodes and decodes a map with boolean values" do
    val = {
      "a" => true,
      "b" => false,
      "c" => true,
      "d" => false
    }

    buf = StringIO.new
    subject.new(:string, :bool).encode(buf, val)
    buf.rewind
    out = subject.decode(buf.read(1), buf)
    out = out.transform_values(&:yarp_bool)
    expect(out).to eq(val)

    buf.rewind
    out = subject.new(:string, :bool).decode(buf.read(1), buf)
    expect(out).to eq(val)
  end
end
