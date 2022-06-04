# frozen_string_literal: true

# Internal: Extensions for Ruby's Time class
class Time
  # Public: Alias to Time.now.utc
  def self.stamp
    now.utc
  end

  # Public: Converts a Time instance into an RFC3339 timestamp
  def rfc3339
    to_datetime.rfc3339
  end
end
