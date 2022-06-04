# frozen_string_literal: true

RSpec.describe Yarp::Proto::EncodedStruct do
  subject { described_class }

  class OtherTS < Yarp::Structure
    yarp_meta id: 0x2, package: "io.vito", name: "TS2"

    primitive :project, :string, 0
    primitive :role, :string, 1
  end

  class TS < Yarp::Structure
    yarp_meta id: 0x1, package: "io.vito", name: "TS"

    primitive :id, :int64, 0
    primitive :name, :string, 1
    primitive :email, :string, 2
    array :keys, 3, of: :string
    array :other, 4, of: OtherTS
    map :a_map, 5, key: :string, value: :int64
    oneof 6 do
      primitive :one_of_a, :string, 0
      primitive :one_of_b, :int64, 1
      primitive :one_of_c, :bool, 2
    end
    primitive :is_admin, :bool, 7
    struct :single_other, OtherTS, 8
    struct :optional_ts, OtherTS, 9, optional: true
  end

  it "encodes and decodes struct data" do
    inst = TS.new(
      id: 102_030,
      name: "Vito",
      email: "hey@vito.io",
      keys: %w[a b c],
      other: [
        { project: "foo", role: "bar" }
      ],
      a_map: {
        "a" => 1,
        "b" => 2,
        "c" => 3,
        "d" => 4
      },
      one_of_a: "test",
      is_admin: true,
      single_other: {
        project: "fuz",
        role: "baz"
      }
    )

    buf = StringIO.new
    subject.encode(buf, inst)
    buf.seek(0)
    decoded = Yarp::Proto.decode_any(buf)
    expect(decoded).to be_a(Yarp::Proto::EncodedStruct)
    val = decoded.specialize
    expect(val.id).to eq 102_030
    expect(val.name).to eq "Vito"
    expect(val.email).to eq "hey@vito.io"
    expect(val.keys).to eq %w[a b c]
    expect(val.other.length).to eq 1
    expect(val.other.first).to be_kind_of OtherTS
    expect(val.other.first.project).to eq "foo"
    expect(val.other.first.role).to eq "bar"
    expect(val.a_map).to eq({
      "a" => 1,
      "b" => 2,
      "c" => 3,
      "d" => 4
    })
    expect(val).to have_one_of_a
    expect(val.one_of_a).to eq "test"
    expect(val.is_admin).to eq true
    expect(val.single_other).to be_kind_of OtherTS
    expect(val.single_other.project).to eq "fuz"
    expect(val.single_other.role).to eq "baz"
  end
end
