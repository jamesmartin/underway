# encoding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "underway/version"

Gem::Specification.new do |spec|
  spec.name          = "underway"
  spec.version       = Underway::VERSION
  spec.authors       = ["James Martin"]
  spec.email         = ["underway-gem@jmrtn.com"]
  spec.summary       = %q{Quick prototyping helpers for building GitHub Apps.}
  spec.description   = %q{Generate tokens and interact with the GitHub Rest API as a GitHub App.}
  spec.homepage      = "https://github.com/jamesmartin/underway"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"

  spec.add_runtime_dependency "addressable", "~> 2.3"
  spec.add_runtime_dependency "jwt", "~> 2.1"
  spec.add_runtime_dependency "octokit", "~> 4.0"
  spec.add_runtime_dependency "sequel"
  spec.add_runtime_dependency "sqlite3", "~> 1.3"
end
