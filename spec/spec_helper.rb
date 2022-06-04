# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "spec/"
end

require "byebug"
require "hexdump"
require "yarp"
require "timecop"
require "tempfile"

# Timecop's safe mode forces one to use Timecop with the block syntax since it
# always puts time back the way it was. If you are running in safe mode and use
# Timecop without the block syntax Timecop::SafeModeException will be raised to
# indicate the operation is not safe.
Timecop.safe_mode = true

require_relative "support/helpers"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Shhhh. Can you hear it? No? Nothing? That's because we're sending everything
  # to a blackhole.
  Yarp.configure.logger = Logrb.new(StringIO.new)

  config.include Helpers
end
