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
    app/components/bali/gantt/GanttFlow.jsx
    app/components/bali/block_editor/BlockNoteEditorWrapper.jsx
    lib/bali/form_builder/select_fields.rb
  ].freeze

  # Every extension under app/ and lib/bali/ that can carry a class name. The React
  # components are `.jsx`; `.ts`/`.tsx`/`.mjs`/`.cjs` are listed so the day one lands it
  # is scanned from the start instead of reopening #1124 under a new extension.
  CLASS_BEARING = %w[rb erb js jsx ts tsx mjs cjs].freeze

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

  # The glob used to say `*.{rb,erb,js}`: the ten `.jsx` files of Gantt and BlockEditor
  # were never scanned, and a host on the documented `@import` compiled without a
  # warning and rendered both components with 49 of their classes missing (#1124).
  # Rather than pin the one extension that bit, this sweeps every file in the tree
  # that could carry a class and fails on the first one no @source reaches.
  def test_no_class_bearing_file_escapes_every_source_glob
    reached = sources.flat_map { |glob| scanned(glob) }.to_set
    escaped = class_bearing_files.reject { |file| reached.include?(file) }

    assert_empty escaped.map { |file| file.delete_prefix("#{Bali::Engine.root}/") },
                 "Files no @source in engine.css reaches"
  end

  private

  def class_bearing_files
    roots = %w[app lib/bali].map { |dir| Bali::Engine.root.join(dir) }
    roots.flat_map { |dir| Dir.glob("#{dir}/**/*.{#{CLASS_BEARING.join(',')}}") }
  end

  def sources
    ENGINE_CSS.read.scan(/^@source\s+"([^"]+)";/).flatten
  end

  def scanned(glob)
    Dir.glob(File.expand_path(glob, ENGINE_CSS.dirname))
  end
end
