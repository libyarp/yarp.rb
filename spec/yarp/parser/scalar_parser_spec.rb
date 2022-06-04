# frozen_string_literal: true

RSpec.describe Yarp::Parser::ScalarParser do
  context "unsigned integer" do
    0.upto(1024).each do |i|
      it "encodes and decodes #{i}" do
        buffer = StringIO.new
        Yarp::Proto::Scalar.encode_integer(buffer, i)
        parse(buffer).with(subject).matching do |v|
          expect(v).not_to be_signed
          expect(v).to eq i
        end
      end
    end
  end

  context "signed integer" do
    -512.upto(512).each do |i|
      it "encodes and decodes #{i}" do
        buffer = StringIO.new
        Yarp::Proto::Scalar.encode_integer(buffer, i, signed: true)
        parse(buffer).with(subject).matching do |v|
          expect(v).to be_signed
          expect(v).to eq i
        end
      end
    end
  end

  context "boolean" do
    it "encodes and decodes 'true'" do
      buffer = StringIO.new
      Yarp::Proto::Scalar.encode_boolean(buffer, true)
      parse(buffer).with(subject).matching do |v|
        expect(v).to be_signed
        expect(v).to be_zero
      end
    end

    it "encodes and decodes 'false'" do
      buffer = StringIO.new
      Yarp::Proto::Scalar.encode_boolean(buffer, false)
      parse(buffer).with(subject).matching do |v|
        expect(v).not_to be_signed
        expect(v).to be_zero
      end
    end
  end
end
