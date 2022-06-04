# frozen_string_literal: true

RSpec.describe Yarp::OneofDescriptor do
  it "rejects nested calls" do
    expect { subject.oneof }.to raise_error(TypeError)
  end
end
