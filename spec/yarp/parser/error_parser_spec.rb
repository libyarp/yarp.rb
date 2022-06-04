# frozen_string_literal: true

RSpec.describe Yarp::Parser::ErrorParser do
  it "parses an error" do
    err = Yarp::Proto::Error.new(
      Yarp::Proto::Error::INTERNAL_ERROR,
      { "Header" => "Value" },
      "Identifier",
      nil
    )
    buf = StringIO.new
    err.encode(buf)
    parse(buf).with(subject).matching do |dec|
      expect(dec.kind).to eq err.kind
      expect(dec.headers).to eq err.headers
      expect(dec.identifier).to eq err.identifier
      expect(dec.user_data).to eq err.user_data
    end
  end
end
