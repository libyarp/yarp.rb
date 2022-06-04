# frozen_string_literal: true

RSpec.describe Yarp::Parser::RequestParser do
  it "parses a request" do
    req = Yarp::Proto::Request.new(0x102030, {
      "RequestID" => "Hello!"
    })
    buf = StringIO.new
    req.encode(buf)
    parse(buf).with(subject).matching do |r|
      expect(r.method_id).to eq req.method_id
      expect(r.headers).to eq req.headers
    end
  end
end
