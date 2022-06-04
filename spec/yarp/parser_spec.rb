# frozen_string_literal: true

RSpec.describe Yarp do
  it("provides a Scalar parser") { expect(Yarp::Parser::ScalarParser).not_to be_nil }
  it("provides a Float parser") { expect(Yarp::Parser::FloatParser).not_to be_nil }
  it("provides an Array parser") { expect(Yarp::Parser::ArrayParser).not_to be_nil }
  it("provides a Struct parser") { expect(Yarp::Parser::EncodedStructParser).not_to be_nil }
  it("provides a String parser") { expect(Yarp::Parser::StringParser).not_to be_nil }
  it("provides a Map parser") { expect(Yarp::Parser::MapParser).not_to be_nil }
  it("provides an Oneof parser") { expect(Yarp::Parser::OneofParser).not_to be_nil }
  it("provides a Request parser") { expect(Yarp::Parser::RequestParser).not_to be_nil }
  it("provides a Response parser") { expect(Yarp::Parser::ResponseParser).not_to be_nil }
  it("provides an Error parser") { expect(Yarp::Parser::ErrorParser).not_to be_nil }
end
