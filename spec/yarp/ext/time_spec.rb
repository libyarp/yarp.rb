# frozen_string_literal: true

RSpec.describe Time do
  it "implements Time#stamp" do
    ts = "2022-06-03 02:00:25.389488 UTC"
    Timecop.freeze(DateTime.parse(ts).to_time) do
      expect(Time.stamp.rfc3339).to eq "2022-06-03T02:00:25+00:00"
    end
  end
end
