# frozen_string_literal: true

RSpec.describe Yarp::Proto::Scalar do
  subject { described_class }

  context "unsigned integer" do
    0.upto(1024).each do |i|
      it "encodes and decodes #{i}" do
        buffer = StringIO.new
        subject.encode_integer(buffer, i)
        buffer.seek(0)
        expect(subject.decode(buffer.read(1), buffer)).to eq i
      end
    end
  end

  context "signed integer" do
    -512.upto(512).each do |i|
      it "encodes and decodes #{i}" do
        buffer = StringIO.new
        subject.encode_integer(buffer, i, signed: true)
        buffer.seek(0)
        expect(subject.decode(buffer.read(1), buffer)).to eq i
      end
    end
  end

  context "boolean" do
    it "encodes and decodes 'true'" do
      buf = StringIO.new
      subject.encode_boolean(buf, true)
      buf.seek(0)
      expect(subject.decode(buf.read(1), buf).yarp_bool).to eq true
    end

    it "encodes and decodes 'false'" do
      buf = StringIO.new
      subject.encode_boolean(buf, false)
      buf.seek(0)
      expect(subject.decode(buf.read(1), buf).yarp_bool).to eq false
    end
  end
end
