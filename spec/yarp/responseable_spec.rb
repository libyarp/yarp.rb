# frozen_string_literal: true

RSpec.describe Yarp::Responseable do
  subject do
    @logger = double(:logger)

    @driver = double(:driver).tap do |d|
      allow(d).to receive(:logger).and_return(@logger)
      allow(d).to receive(:handler_can_stream?).and_return(true)
    end

    @request = double(:request).tap do |r|
      allow(r).to receive(:headers).and_return({})
    end

    Class.new do
      include Yarp::Service
    end.new(@driver, @request)
  end

  it "accepts #add_header before stream started" do
    subject.add_header foo: "bar"
    expect(subject.response_headers).to eq({ foo: "bar" })
  end

  it "accepts #set_headers before stream started" do
    subject.set_headers foo: "bar"
    expect(subject.response_headers).to eq({ foo: "bar" })
  end

  it "rejects #add_header after stream started" do
    subject.instance_variable_set :@streaming, true
    expect(@logger).to receive(:warn) do |msg|
      expect(msg).to match(/: #add_headers called after streaming data. Headers must be set before streaming.$/)
    end
    subject.add_header foo: "bar"
    expect(subject.response_headers).to eq({})
  end

  it "rejects #set_headers after stream started" do
    subject.instance_variable_set :@streaming, true
    expect(@logger).to receive(:warn) do |msg|
      expect(msg).to match(/: #set_headers called after streaming data. Headers must be set before streaming.$/)
    end
    subject.set_headers foo: "bar"
    expect(subject.response_headers).to eq({})
  end
end
