# frozen_string_literal: true

RSpec.describe Yarp::Parser::OneofParser do
  it "encodes and decodes a string value" do
    val = Yarp::Proto::Oneof.new(45, "Hello, World!")
    buf = StringIO.new
    val.encode(buf)
    parse(buf).with(subject).matching do |v|
      expect(v.index).to eq 45
      expect(v.data).to eq "Hello, World!"
    end
  end
end
