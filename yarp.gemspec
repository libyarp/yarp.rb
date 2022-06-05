# frozen_string_literal: true

require_relative "lib/yarp/version"

Gem::Specification.new do |spec|
  spec.name = "yarp"
  spec.version = Yarp::VERSION
  spec.authors = ["Victor Gama"]
  spec.email = ["hey@vito.io"]

  spec.summary = "YARP for Ruby"
  spec.description = "YARP Client and Server implementations for Ruby"
  spec.homepage = "https://github.com/libyarp/yarp.rb"
  spec.license = "LGPL-3.0-or-later"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "eventmachine", "~> 1.2.7"
  spec.add_dependency "logrb", "~> 0.1.3"
  spec.metadata["rubygems_mfa_required"] = "true"
end
