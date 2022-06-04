# frozen_string_literal: true

RSpec.describe Yarp::Parser::FloatParser do
  it "encodes and decodes a float32 value" do
    buf = StringIO.new
    Yarp::Proto::Float.encode32(buf, Math::PI)
    parse(buf).with(subject).matching { |v| expect(v).to be_within(0.0001).of(Math::PI) }
  end

  it "encodes and decodes a float64 value" do
    buf = StringIO.new
    Yarp::Proto::Float.encode64(buf, Math::PI)
    parse(buf).with(subject).matching { |v| expect(v).to be_within(0.0001).of(Math::PI) }
  end
end
