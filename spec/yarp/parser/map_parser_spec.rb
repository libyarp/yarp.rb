# frozen_string_literal: true

RSpec.describe Yarp::Parser::MapParser do
  it "parses maps" do
    val = {
      "a" => 1,
      "b" => 2,
      "c" => 3,
      "d" => 4
    }

    buf = StringIO.new
    Yarp::Proto::Map[:string, :uint8].encode(buf, val)
    parse(buf).with(subject).emitting(val)
  end

  it "encodes and decodes a map with boolean values" do
    val = {
      "a" => true,
      "b" => false,
      "c" => true,
      "d" => false
    }

    buf = StringIO.new
    Yarp::Proto::Map[:string, :bool].encode(buf, val)
    parse(buf).with(subject).matching do |v|
      v = Yarp::Proto::Map[:string, :bool].convert(v)
      expect(v).to eq val
    end
  end
end
