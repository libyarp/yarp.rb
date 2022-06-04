# frozen_string_literal: true

RSpec.describe Yarp::Parser::ArrayParser do
  it "parses arrays of strings" do
    buf = StringIO.new
    items = %w[
      Coffee
      Caffé
      Covfefe
    ]
    Yarp::Proto::Array[:string].encode(buf, items)
    parse(buf).with(subject).emitting(items)
  end

  it "parses arrays of ints" do
    buf = StringIO.new
    items = [0x0, 0xC0, 0xFF, 0xEE]
    Yarp::Proto::Array[:uint8].encode(buf, items)
    parse(buf).with(subject).emitting(items)
  end

  it "parses arrays of floats" do
    buf = StringIO.new
    items = [
      0.1,
      0.2,
      0.3
    ]
    Yarp::Proto::Array[:float32].encode(buf, items)
    parse(buf).with(subject).matching do |decoded|
      expect(decoded[0]).to be_within(0.0001).of(0.1)
      expect(decoded[1]).to be_within(0.0001).of(0.2)
      expect(decoded[2]).to be_within(0.0001).of(0.3)
    end
  end

  it "parses an empty arry" do
    buf = StringIO.new
    items = []
    Yarp::Proto::Array[:uint8].encode(buf, items)
    parse(buf).with(subject).emitting([])
  end
end
