# frozen_string_literal: true

RSpec.describe Yarp::Parser::EncodedStructParser do
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
    Yarp::Proto::EncodedStruct.encode(buf, inst)
    parse(buf).with(subject).matching do |decoded|
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
end
