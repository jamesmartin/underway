#ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "timecop"
require_relative "./sequel_helper.rb"

Timecop.safe_mode = true # Never, NEVER, allow arbitrary mutation of time without a block
