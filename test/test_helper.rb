# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    SimpleCov.enable_coverage(:branch)

    SimpleCov.add_filter(/test/)
  end
end

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "r"

require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new)

module Minitest
  class Test
    extend T::Sig
  end
end
