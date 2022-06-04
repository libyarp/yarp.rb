# frozen_string_literal: true

RSpec.describe Yarp::Parser::ResponseParser do
  it "parses a response" do
    resp = Yarp::Proto::Response.new({
      "Header" => "Value"
    }, true)
    buf = StringIO.new
    resp.encode(buf)
    parse(buf).with(subject).matching do |r|
      expect(r.headers).to eq resp.headers
      expect(r.stream).to eq resp.stream
    end
  end
end
