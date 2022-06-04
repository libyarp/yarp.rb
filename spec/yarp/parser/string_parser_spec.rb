# frozen_string_literal: true

RSpec.describe Yarp::Parser::StringParser do
  it "encodes and decodes a string value" do
    buf = StringIO.new
    Yarp::Proto::String.encode(buf, "Hello, World!")
    parse(buf).with(subject).emitting("Hello, World!")
  end

  it "encodes and decodes an empty string" do
    buf = StringIO.new
    Yarp::Proto::String.encode(buf, "")
    parse(buf).with(subject).emitting("")
  end
end
