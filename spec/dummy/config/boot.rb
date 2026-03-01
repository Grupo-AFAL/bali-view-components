# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../../../Gemfile", __dir__)

# Start SimpleCov BEFORE bundler loads gems so Coverage.start tracks lib/ files.
# Without this, `rails test` boots Rails (and loads all gem code) before
# test_helper.rb runs, so Coverage misses all files loaded at boot time.
if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch

    add_filter "test/"
    add_filter "spec/"
    add_filter ".github/"
    add_filter "lib/bali/version"
    add_filter(/preview.rb/)

    # Pure data files (SVG constants, icon name mappings) — not business logic
    add_filter "app/components/bali/icon/default_icons.rb"
    add_filter "app/components/bali/icon/lucide_mapping.rb"
    add_filter "app/components/bali/icon/kept_icons.rb"

    # Importmap pin configuration — not unit-testable
    add_filter "lib/bali/importmap/"

    # Generator templates
    add_filter "lib/generators/"

    # Test helper (should not count toward app coverage)
    add_filter "lib/bali/tenancy_tests_helper.rb"

    add_group "Components", "app/components/bali"
    add_group "Lib", "lib/"

    track_files "{app,lib}/**/*.rb"

    # Enforced per AFAL handbook. Never let this drop below 80%.
    minimum_coverage line: 80
  end
end

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
