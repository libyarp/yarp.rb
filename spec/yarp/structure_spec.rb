# frozen_string_literal: true

RSpec.describe Yarp::Structure do
  context "oneof" do
    it "sets oneof fields" do
      c = Class.new(described_class) do
        oneof 1 do
          map :bla, 30, key: :string, value: :string
          array :foo, 31, of: :string
        end
      end

      x = c.new(foo: ["bar"])
      expect(x.foo).to eq ["bar"]
    end
  end

  context "validation" do
    it "rejects struct with non-zero index" do
      c = Class.new(described_class) do
        primitive :foo, :string, 1
      end

      expect { c.validate! }.to raise_error(Yarp::MinFieldNotZeroError)
    end

    it "rejects struct with gaps" do
      c = Class.new(described_class) do
        primitive :foo, :string, 0
        primitive :bar, :string, 2
      end

      expect { c.validate! }.to raise_error(Yarp::FieldGapError)
    end
  end

  context "initialization" do
    let(:c) do
      Class.new(described_class) do
        primitive :foo, :string, 0
        primitive :bar, :string, 1
      end
    end

    it "sets by hash" do
      i = c.new(foo: "f", bar: "b")
      expect(i.foo).to eq "f"
      expect(i.bar).to eq "b"
    end

    it "sets by index" do
      i = c.new("f", "b")
      expect(i.foo).to eq "f"
      expect(i.bar).to eq "b"
    end
  end

  context "unknown fields" do
    let(:c) do
      Class.new(described_class) do
        primitive :foo, :string, 0
        primitive :bar, :string, 1
      end
    end

    it "warns" do
      allow(Yarp).to receive(:handle_unknown_field_initialization_with).and_return(:warn)
      msg = /\[Yarp\] Attempt to set unknown field d for #<Class:0x/
      expect { c.new(d: "hai!") }.to output(msg).to_stderr
    end

    it "raises" do
      allow(Yarp).to receive(:handle_unknown_field_initialization_with).and_return(:exception)
      expect { c.new(d: "hai!") }.to raise_error(Yarp::UnknownFieldInitializationError)
    end

    it "does nothing" do
      allow(Yarp).to receive(:handle_unknown_field_initialization_with).and_return(:nothing)
      expect { c.new(d: "hai!") }.not_to output.to_stderr
    end
  end

  context "all types" do
    it "validates a long structure" do
      c = Class.new(described_class) do
        yarp_meta id: 0xf7eeb0291b568f1e, package: "io.vito.yarp", name: :AllTypes

        primitive :a, :uint8, 0
        primitive :b, :uint16, 1
        primitive :c, :uint32, 2
        primitive :d, :uint64, 3
        primitive :e, :int8, 4
        primitive :f, :int16, 5
        primitive :g, :int32, 6
        primitive :h, :int64, 7
        primitive :i, :bool, 8
        primitive :j, :float32, 9
        primitive :k, :float64, 10
        array :l, 11, of: :string
        map :m, 12, key: :string, value: :string
        oneof(13) do
          primitive :n, :uint64, 0
          primitive :o, :string, 1
          primitive :p, :bool, 2
        end
        primitive :q, :string, 14, optional: true
        map :u, 15, key: :string, value: Yarp::Proto::Array[:uint8]
      end
      c.validate!
    end
  end
end
