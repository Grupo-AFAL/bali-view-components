# frozen_string_literal: true

require "test_helper"

# tailwindcss-rails (>= 4.3) bundles an engine's Tailwind sources only when
# app/assets/tailwind/<engine_name>/engine.css exists under the engine root. The
# lookup is by engine_name, so the directory and the Engine class are one
# contract — and the line hosts write, `@import "../builds/tailwind/bali";`,
# resolves to whatever that file says. These keep its @source globs honest: each
# resolves relative to engine.css itself and must reach what the installation
# guide promises hosts is scanned — the components, the JavaScript that writes
# class names at runtime, and the FormBuilder under lib/, the only place the
# form error classes come from.
class BaliTailwindEngineCssTest < ActiveSupport::TestCase
  ENGINE_CSS = Bali::Engine.root.join("app/assets/tailwind/#{Bali::Engine.engine_name}/engine.css")

  MUST_BE_SCANNED = %w[
    app/components/bali/button/component.rb
    app/components/bali/card/component.html.erb
    app/components/bali/modal/index.js
    lib/bali/form_builder/select_fields.rb
  ].freeze

  def test_engine_css_lives_where_tailwindcss_rails_looks
    assert_equal "bali", Bali::Engine.engine_name
    assert_predicate ENGINE_CSS, :exist?
  end

  def test_every_source_glob_matches_files_in_the_gem
    assert_not_empty sources, "engine.css declares no @source"
    sources.each do |glob|
      assert_not_empty scanned(glob), "@source #{glob.inspect} matches nothing"
    end
  end

  def test_sources_reach_the_files_hosts_depend_on
    files = sources.flat_map { |glob| scanned(glob) }
    MUST_BE_SCANNED.each do |relative|
      assert_includes files, Bali::Engine.root.join(relative).to_s,
                      "#{relative} is not reached by any @source in engine.css"
    end
  end

  private

  def sources
    ENGINE_CSS.read.scan(/^@source\s+"([^"]+)";/).flatten
  end

  def scanned(glob)
    Dir.glob(File.expand_path(glob, ENGINE_CSS.dirname))
  end
end
