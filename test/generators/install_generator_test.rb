# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/bali/install/install_generator"

# `bin/rails g bali:install` writes the wiring that the seven apps in the fleet
# each copied out of the one next door.
#
# The measurement that decides what belongs here: across those seven
# `app/assets/tailwind/application.css` files exactly THREE substantive lines are
# identical, `config/initializers/bali.rb` shares exactly ONE, and
# `controllers/index.js` shares `registerAll` + `registerCharts`. Everything else
# diverges — the AFAL theme is done four different ways — so the generator writes
# the shared part and SAYS the rest. A generator that guessed at the divergent
# part would be a seventh way of doing it.
#
# THE SECOND MEASUREMENT, and the reason the fixtures below are not one virgin
# `rails new` tree: what "already wired" looks like in those same seven files. A
# fixture the generator itself could have written only ever tests it against its
# own spelling. The fleet's real shapes are fixtures instead — two symbols on one
# import line, identity's aliased imports from an internal path, `daisyui` in
# `devDependencies`, importmap-rails' eager loader — and what comes out is parsed
# by node, because a duplicate import binding is a parse error before any bundling.
class BaliInstallGeneratorTest < Rails::Generators::TestCase
  tests Bali::InstallGenerator
  destination Rails.root.join("tmp/generator_test")
  setup :prepare_destination

  # THE ORDER IS THE POINT, and the reason is not the one people reach for.
  # `@import "tailwindcss"` is the line that emits `@layer theme, base,
  # components, utilities`; Bali's sheets must come after it or they land outside
  # the cascade Tailwind set up. (It is NOT about beating daisyUI: daisyUI 5
  # emits inside `@layer utilities` and outranks `@layer components` by design,
  # whatever order the imports are in.)
  def test_writes_the_three_shared_css_lines_after_tailwind
    host_app
    run_generator

    assert_file "app/assets/tailwind/application.css" do |css|
      assert_match(/@import "tailwindcss";/, css)
      assert_match(%r{@import "\.\./builds/tailwind/bali";}, css)
      assert_match(%r{@import "bali-view-components/css/bali\.css";}, css)

      assert_operator css.index('@import "tailwindcss"'), :<,
                      css.index('@import "../builds/tailwind/bali"')
      assert_operator css.index('@import "tailwindcss"'), :<,
                      css.index('@import "bali-view-components/css/bali.css"')
    end
  end

  # daisyUI is a REQUIRED peer, not a theming nicety: the Ruby components emit its
  # class names, so an app without the plugin renders them unstyled. All seven
  # applications carry the directive.
  def test_writes_the_daisyui_plugin_when_the_host_has_none
    host_app
    run_generator

    assert_file "app/assets/tailwind/application.css" do |css|
      assert_match(/^@plugin "daisyui";$/, css)
      assert_operator css.index('@import "tailwindcss"'), :<, css.index('@plugin "daisyui"')
      assert_operator css.index('@plugin "daisyui"'), :<,
                      css.index('@import "../builds/tailwind/bali"')
    end
  end

  # Six of the seven write it in block form, with their themes inside. Searching
  # the file for the bare `@plugin "daisyui";` this generator would write finds
  # nothing there, and a second plugin line is what comes out.
  def test_leaves_a_block_form_daisyui_plugin_alone
    host_app
    write "app/assets/tailwind/application.css", <<~CSS
      @import "tailwindcss";
      @plugin "daisyui" {
        themes: light --default, dark;
      }
    CSS

    run_generator

    assert_file "app/assets/tailwind/application.css" do |css|
      assert_equal 1, css.scan(/^@plugin "daisyui"/).size
      assert_match(/themes: light --default, dark;/, css)
      assert_operator css.index("themes:"), :<, css.index('@import "../builds/tailwind/bali"')
    end
  end

  # The bridge's failure mode is silence: a hand-written `@source` at the gem
  # directory matches nothing on the next machine and Tailwind does not complain,
  # it just drops every Bali class. A comment that does not say so invites the
  # glob back.
  def test_the_css_comment_warns_off_the_source_glob_that_fails_silently
    host_app
    run_generator

    assert_file "app/assets/tailwind/application.css" do |css|
      assert_match(/@source/, css, "the comment has to name the thing it is replacing")
      assert_match(/silent|silence/i, css)
      assert_match(/engine\.css/, css)
    end
  end

  def test_writes_the_one_initializer_line_the_whole_fleet_shares
    host_app
    run_generator

    assert_file "config/initializers/bali.rb" do |rb|
      assert_match(
        /^Rails\.application\.config\.action_view\.default_form_builder = "Bali::FormBuilder"$/, rb
      )
      assert_match(/ActionView::Base/, rb, "the comment has to say which spelling is wrong and why")
      assert_match(/on_load/, rb)
    end
  end

  # The Block Editor already defaults to `false` in lib/bali.rb, so the flag turns
  # it ON. Without it the initializer must not mention either editor at all — a
  # written `= false` is a line a host later has to understand before changing.
  def test_the_editors_are_absent_unless_a_flag_asks_for_them
    host_app
    run_generator

    assert_file "config/initializers/bali.rb" do |rb|
      assert_no_match(/block_editor_enabled/, rb)
      assert_no_match(/rich_text_editor_enabled/, rb)
    end
    assert_file "package.json" do |json|
      assert_no_match(%r{@blocknote/core}, json)
    end
  end

  # No `--rich-text-editor` twin for the flag below. TipTap is deprecated in v3
  # and removed in v4, and a flag is public surface with a known expiry date: it
  # would have to be documented, carried through a major and then taken away. The
  # one line that turns it on is printed instead.
  def test_the_deprecated_editor_has_no_flag_only_a_printed_line
    host_app

    output = run_generator

    assert_not_includes Bali::InstallGenerator.class_options.keys, :rich_text_editor
    assert_match(/rich_text_editor_enabled = true/, output)
    assert_match(/DEPRECATED/, output)
  end

  def test_block_editor_flag_turns_it_on_and_brings_its_packages
    host_app
    run_generator %w[--block-editor]

    assert_file "config/initializers/bali.rb" do |rb|
      assert_match(/^Bali\.block_editor_enabled = true$/, rb)
      assert_match(/block_editor_upload_authorize/, rb)
    end
    assert_file "package.json" do |json|
      %w[@blocknote/core @blocknote/mantine @blocknote/react @mantine/core react].each do |pkg|
        assert_match(/#{Regexp.escape(pkg)}/, json)
      end
    end
    assert_file "app/javascript/controllers/index.js" do |js|
      assert_match(/registerBlockEditor\(application\)/, js)
    end
  end

  # `registerAll` already installs the confirm dialog — the issue asked for a
  # second call and it would be a no-op. The five apps that DO call
  # `installConfirmDialog` pass Spanish button labels, which is a localisation
  # choice no generator can make for them.
  def test_registers_the_controllers_without_reinstalling_the_confirm_dialog
    host_app
    run_generator

    assert_file "app/javascript/controllers/index.js" do |js|
      assert_match(/import \{ registerAll \} from "bali-view-components"/, js)
      assert_match(/^registerAll\(application\)$/, js)
      assert_match(/^registerCharts\(application\)$/, js)
      assert_no_match(/installConfirmDialog/, js)
    end
  end

  # Only what a bundler must resolve to build the host at all. chart.js is not
  # that: its import is guarded, the build succeeds without it, and installing it
  # anyway costs an app that never draws a chart 485 KB of bundle — measured on a
  # toy app, 1.1 MB with it against 616 KB without.
  def test_adds_the_required_peers_and_leaves_the_optional_ones_out
    host_app
    run_generator

    assert_file "package.json" do |json|
      package = JSON.parse(json)
      dependencies = package.fetch("dependencies")

      %w[@hotwired/stimulus @hotwired/turbo-rails lodash.throttle lodash.debounce
         rrule date-fns @rails/activestorage @rails/request.js].each do |pkg|
        assert_includes dependencies.keys, pkg
      end
      assert_includes dependencies.keys, "bali-view-components"
      assert_match(/v#{Regexp.escape(Bali::VERSION)}/, dependencies.fetch("bali-view-components"))

      %w[chart.js tippy.js sortablejs flatpickr slim-select qr-scanner
         @glidejs/glide].each do |optional|
        assert_not_includes dependencies.keys, optional
      end
      assert_equal "1.2.3", dependencies.fetch("leftpad"), "an existing dependency was rewritten"
    end
  end

  # daisyui is a Tailwind plugin: the CSS build consumes it and the app bundle
  # never imports it. All seven applications keep it in `devDependencies`, so an
  # app generated with it in `dependencies` is the only one in the fleet that does
  # not.
  def test_the_build_time_plugin_goes_where_the_fleet_keeps_it
    host_app
    run_generator

    assert_file "package.json" do |json|
      package = JSON.parse(json)

      assert_equal ">=5.7.0", package.dig("devDependencies", "daisyui")
      assert_nil package.dig("dependencies", "daisyui")
    end
  end

  # Idempotence is the whole difference between a generator and a snippet in a
  # guide: a host re-runs it after an upgrade to pick up a new line.
  def test_running_it_twice_writes_nothing_twice
    host_app
    run_generator
    run_generator

    assert_file "app/assets/tailwind/application.css" do |css|
      assert_equal 1, css.scan('@import "../builds/tailwind/bali"').size
      assert_equal 1, css.scan('@import "bali-view-components/css/bali.css"').size
    end
    assert_file "config/initializers/bali.rb" do |rb|
      # The full line, not the bare word: the comment above it quotes the WRONG
      # spelling, `ActionView::Base.default_form_builder =`, on purpose.
      assert_equal 1, rb.scan(/^Rails\.application\.config\.action_view\.default_form_builder/).size
    end
    assert_file "app/javascript/controllers/index.js" do |js|
      assert_equal 1, js.scan("registerAll(application)").size
      assert_equal 1, js.scan(/import \{ registerAll \}/).size
    end
  end

  # AND THE ASSERTION THAT ACTUALLY BACKS THE PROMISE. The test above runs the
  # generator over a tree the generator itself wrote, which proves only that it
  # agrees with its own spelling. What the README and the CHANGELOG claim is that
  # running it on an application wired BY HAND writes nothing — so: the fleet's
  # shape, byte-compared before and after.
  def test_running_it_on_an_app_wired_by_hand_writes_nothing
    host_app(css: :fleet, javascript: :fleet, package_json: :fleet, initializer: :fleet)
    before = snapshot

    output = run_generator

    assert_equal before, snapshot, "it rewrote a file that was already wired by hand"
    assert_equal 4, output.scan(/identical/).size, output
  end

  # Five of the seven put a second symbol on that import line. A substring search
  # for the generator's own `import { registerAll } from "bali-view-components"`
  # does not find it, so a second import goes in and `yarn build` dies with `The
  # symbol "registerAll" has already been declared`.
  def test_leaves_an_import_that_carries_a_second_symbol_alone
    host_app(javascript: :fleet)

    run_generator

    assert_file "app/javascript/controllers/index.js" do |js|
      assert_equal 1, js.scan(/^import .*registerAll/).size, "a second import of registerAll"
      assert_equal 1, js.scan("registerAll(application)").size
      assert_match(/installConfirmDialog\(\{ acceptText: "Aceptar"/, js)
    end
  end

  # identity imports `registerAll` twice under two aliases, from two esbuild
  # aliases onto paths INSIDE the gem. Adding the public import next to those is
  # not a syntax error — it is every controller registered a second time.
  def test_leaves_an_aliased_import_from_an_internal_path_alone
    host_app(javascript: :identity)

    run_generator

    assert_file "app/javascript/controllers/index.js" do |js|
      assert_no_match(/from "bali-view-components"/, js)
      assert_equal 1, js.scan("registerComponents(application)").size
      assert_equal 1, js.scan("registerCharts(application)").size
    end
  end

  # All seven keep `daisyui` in devDependencies, which is where a build-time
  # Tailwind plugin belongs. Reading only `dependencies` puts a second one in the
  # same file, with a different range.
  def test_does_not_duplicate_a_dependency_the_host_keeps_in_dev_dependencies
    host_app(package_json: :fleet)

    run_generator

    assert_file "package.json" do |json|
      package = JSON.parse(json)

      assert_equal 1, json.scan(/"daisyui":/).size
      assert_equal "^5.7.0", package.dig("devDependencies", "daisyui")
      assert_nil package.dig("dependencies", "daisyui")
    end
  end

  # A pin is a decision — a tag, a branch, a `link:` to a local checkout — so the
  # generator does not move it. It says so instead, which is what makes "run it
  # again after a bump" honest rather than silent.
  def test_it_reports_a_pin_that_has_fallen_behind_the_gem_without_moving_it
    host_app(package_json: :fleet)

    output = run_generator

    assert_match(/pins bali-view-components at github:.+#v3\.3\.0/, output)
    assert_match(/v#{Regexp.escape(Bali::VERSION)}/, output)
    assert_file "package.json" do |json|
      assert_match(/#v3\.3\.0/, json, "the pin is the host's to move")
    end
  end

  # No test here can run `yarn build`, but node can say whether the file is a
  # valid module — which is exactly the failure the fleet would have hit: a
  # duplicate `import` binding is a parse error, before any bundling.
  def test_the_javascript_it_writes_parses_as_a_module
    %i[rails_new fleet identity].each do |shape|
      prepare_destination
      host_app(javascript: shape)
      run_generator

      assert_valid_module read_written("app/javascript/controllers/index.js"),
                          "the index.js written over the #{shape} shape does not parse"
    end
  end

  # An initializer a host already wrote is theirs. The generator adds its line to
  # it and touches nothing else.
  def test_it_adds_to_an_existing_initializer_instead_of_replacing_it
    host_app
    write "config/initializers/bali.rb", "Bali.filter_context = ->(c) { c.current_account&.id }\n"

    run_generator

    assert_file "config/initializers/bali.rb" do |rb|
      assert_match(/Bali\.filter_context/, rb)
      assert_match(/default_form_builder = "Bali::FormBuilder"/, rb)
    end
  end

  # Only ONE of the three CSS lines is safe without an npm install, and it is not
  # the obvious pair. Measured on a `rails new` tree with the three written:
  # `bin/rails tailwindcss:build` stops at `Can't resolve
  # 'bali-view-components/css/bali.css'`; with only the daisyUI plugin left,
  # `Can't resolve 'daisyui'`; with the engine bridge alone it builds, because
  # tailwindcss-rails writes that one out of the gem's own path.
  def test_an_app_without_a_package_json_gets_only_the_css_line_that_needs_no_npm
    host_app(package_json: false, javascript: false)

    output = run_generator

    assert_no_file "package.json"
    assert_file "config/initializers/bali.rb"
    assert_file "app/assets/tailwind/application.css" do |css|
      assert_match(%r{@import "\.\./builds/tailwind/bali";}, css)
      assert_no_match(/@plugin "daisyui"/, css)
      assert_no_match(%r{bali-view-components/css/bali\.css}, css)
    end
    assert_match(/@plugin "daisyui";/, output, "the held-back lines have to be printed")
    assert_match(%r{@import "bali-view-components/css/bali\.css";}, output)
  end

  # THE SHAPE A BARE `rails new` PRODUCES, which is not the shape above:
  # `javascript: false` is an importmap app with no Stimulus index, and Rails
  # leaves `app/javascript/controllers/index.js` right there, holding
  # `eagerLoadControllersFrom`. A generator that asks only whether that file exists
  # writes two bare specifiers into it, and measured in Chromium the module then
  # fails to instantiate — `Failed to resolve module specifier
  # "bali-view-components"` — so `eagerLoadControllersFrom` never runs and the host
  # loses EVERY controller of its own, with one console line as the whole evidence.
  def test_an_importmap_app_keeps_its_own_stimulus_index
    host_app(package_json: false, javascript: :importmap, importmap: true)
    before = read_written("app/javascript/controllers/index.js")

    output = run_generator

    assert_equal before, read_written("app/javascript/controllers/index.js"),
                 "the Stimulus layer of a `rails new` app was rewritten"
    assert_file "config/initializers/bali.rb"
    assert_file "app/assets/tailwind/application.css"
    assert_match(/config\/importmap\.rb/, output, "it has to say why it skipped the JavaScript")
    assert_no_match(/the dependencies just written/, output, "it wrote none")
  end

  # cssbundling-rails gives an importmap app a package.json, so "there is a
  # package.json" is not the question either.
  def test_a_package_json_does_not_make_an_importmap_app_a_bundler_app
    host_app(javascript: :importmap, importmap: true)
    before = read_written("app/javascript/controllers/index.js")

    run_generator

    assert_equal before, read_written("app/javascript/controllers/index.js")
  end

  # And with the importmap config gone but the eager loader still in place — an
  # app halfway through a migration — the index itself is the evidence.
  def test_the_eager_loader_alone_is_enough_to_hold_the_javascript_back
    host_app(javascript: :importmap)
    before = read_written("app/javascript/controllers/index.js")

    run_generator

    assert_equal before, read_written("app/javascript/controllers/index.js")
  end

  # `rails new --css=tailwind --javascript=esbuild` does NOT give you the fleet's
  # layout: with a bundler present Rails picks cssbundling-rails, whose entry point
  # is app/assets/stylesheets/application.tailwind.css and whose build is npm, not
  # the tailwindcss:build task. Writing to the tailwindcss-rails path there creates
  # a file nothing compiles — Bali renders unstyled and nothing says why, which is
  # the silent failure #1139 was opened about. Measured on that app with the npm
  # bridge instead: `yarn build:css` emits 403 529 bytes carrying `btn-primary` and
  # daisyUI 5.7.42, against 14 574 bytes for the same entry point cut back to
  # `@import "tailwindcss"`.
  def test_it_writes_into_the_cssbundling_entry_point_when_that_is_the_one_here
    host_app(css: :cssbundling)

    run_generator

    assert_no_file "app/assets/tailwind/application.css"
    assert_file "app/assets/stylesheets/application.tailwind.css" do |css|
      assert_match(%r{@import "bali-view-components/tailwind/engine\.css";}, css)
      assert_no_match(%r{@import "\.\./builds/tailwind/bali"}, css)
      assert_match(/@plugin "daisyui";/, css)
      assert_match(%r{@import "bali-view-components/css/bali\.css";}, css)
    end
  end

  # And the bridge counts as present in either spelling, so an app on one builder
  # does not collect the other one's import.
  def test_either_spelling_of_the_bridge_counts_as_already_there
    host_app(css: :cssbundling)
    run_generator
    before = read_written("app/assets/stylesheets/application.tailwind.css")

    run_generator

    assert_equal before, read_written("app/assets/stylesheets/application.tailwind.css")
  end

  # The other half of the guard: the layout it IS for still gets written.
  def test_a_bundler_app_gets_the_javascript_half
    host_app

    run_generator

    assert_file "app/javascript/controllers/index.js" do |js|
      assert_match(/registerAll\(application\)/, js)
    end
  end

  # `npm build:css` is not a command — measured, `Unknown command: "build:css"`.
  # npm reaches a package.json script only through `npm run`, and a printed step a
  # host cannot paste is worse than no step.
  def test_the_printed_build_step_is_a_command_the_host_can_run
    host_app(css: :cssbundling)

    output = run_generator

    assert_match(/npm run build:css/, output)
    assert_no_match(/npm build:css/, output)
  end

  def test_yarn_takes_the_short_spelling_and_gets_it
    host_app(css: :cssbundling)
    write "yarn.lock", "# THIS IS AN AUTOGENERATED FILE\n"

    output = run_generator

    assert_match(/yarn build:css/, output)
    assert_no_match(/yarn run build:css/, output)
  end

  # THE CSS HALF OF THE BUNDLER QUESTION: not "is there an entry point" but "will
  # anything compile one". Measured before this guard, on an app with a package.json
  # and neither builder: the generator created app/assets/tailwind/application.css
  # and printed `bin/rails tailwindcss:build`, a task that app does not have — a
  # file nobody compiles, which is the silent failure #1139 is about.
  def test_it_writes_no_tailwind_entry_point_where_nothing_would_compile_it
    host_app(css: :none)

    output = run_generator

    assert_no_file "app/assets/tailwind/application.css"
    assert_no_file "app/assets/stylesheets/application.tailwind.css"
    assert_match(/nothing here builds Tailwind/, output)
    assert_no_match(/bin\/rails tailwindcss:build/, output, "it printed a task this app lacks")
    assert_file "config/initializers/bali.rb"
    assert_file "app/javascript/controllers/index.js"
  end

  # The gem alone answers it: tailwindcss-rails writes the entry point on install,
  # and its own build task reads that path whether or not the file is there yet.
  def test_the_gem_in_the_lockfile_is_enough_to_decide_who_owns_the_entry_point
    host_app(css: :none)
    write "Gemfile.lock", "GEM\n  specs:\n    tailwindcss-rails (4.6.0)\n"

    run_generator

    assert_file "app/assets/tailwind/application.css" do |css|
      assert_match(%r{@import "\.\./builds/tailwind/bali";}, css)
    end
  end

  # And cssbundling-rails leaves its own mark, in the file it owns.
  def test_the_build_css_script_is_enough_to_decide_it_the_other_way
    host_app(css: :none, package_json: :cssbundling)

    run_generator

    assert_no_file "app/assets/tailwind/application.css"
    assert_file "app/assets/stylesheets/application.tailwind.css" do |css|
      assert_match(%r{@import "bali-view-components/tailwind/engine\.css";}, css)
    end
  end

  # A generator that adds three lines has no business reformatting the other
  # thirteen. Measured before this: a four-space file with its dependencies in the
  # host's own order came back reindented to two and alphabetised, 13 lines to 24,
  # with "added …" as the whole account of it.
  def test_it_adds_lines_to_package_json_without_reformatting_the_rest
    host_app
    write "package.json", <<~JSON
      {
          "name": "host",
          "private": true,
          "dependencies": {
              "zzz-tools": "1.0.0",
              "leftpad": "1.2.3"
          },
          "devDependencies": {
              "esbuild": "^0.25.0"
          }
      }
    JSON
    before = read_written("package.json")

    run_generator

    after = read_written("package.json")
    added = JSON.parse(after).values_at("dependencies", "devDependencies").flat_map(&:keys) -
            JSON.parse(before).values_at("dependencies", "devDependencies").flat_map(&:keys)
    kept = after.lines.reject { |line| added.any? { |name| line.include?(%("#{name}":)) } }.join

    assert_equal without_trailing_commas(before), without_trailing_commas(kept),
                 "the lines the host wrote came back changed"
    assert_match(/^        "date-fns": /, after, "the file's own indentation was not kept")
    assert_equal %w[zzz-tools leftpad],
                 JSON.parse(after).fetch("dependencies").keys.first(2),
                 "the host's own order was rewritten"
    assert_equal %w[daisyui esbuild], JSON.parse(after).fetch("devDependencies").keys,
                 "an alphabetical section took the new line in its place"
  end

  # ...and where the section IS alphabetical — all seven are — the new lines land
  # in their place instead of in a block at the end.
  def test_an_alphabetical_section_stays_alphabetical
    host_app
    run_generator

    dependencies = JSON.parse(read_written("package.json")).fetch("dependencies").keys

    assert_equal dependencies.sort, dependencies
  end

  private

  def without_trailing_commas(json) = json.gsub(/,\n/, "\n")

  WRITTEN_FILES = [
    "app/assets/tailwind/application.css", "config/initializers/bali.rb",
    "app/javascript/controllers/index.js", "package.json"
  ].freeze

  def snapshot = WRITTEN_FILES.index_with { |path| read_written(path) }

  def read_written(path) = File.read(File.join(destination_root, path))

  def assert_valid_module(source, message)
    skip "node is not on PATH" unless system("node", "--version", out: File::NULL, err: File::NULL)

    output = IO.popen([ "node", "--input-type=module", "--check" ], "r+",
                      err: [ :child, :out ]) do |node|
      node.write(source)
      node.close_write
      node.read
    end

    assert_predicate $CHILD_STATUS, :success?, "#{message}\n#{output}"
  end

  # `rails new --css=tailwind --javascript=esbuild`, which is the app this
  # generator is aimed at — or, with `:fleet` / `:identity`, one of the two shapes
  # the seven applications actually have.
  def host_app(package_json: true, javascript: true, css: :rails_new, initializer: false,
               importmap: false)
    case css
    when :cssbundling
      write "app/assets/stylesheets/application.tailwind.css", %(@import "tailwindcss";\n)
    when :none then nil
    else
      write "app/assets/tailwind/application.css",
            css == :fleet ? fleet_css : %(@import "tailwindcss";\n)
    end

    write "config/initializers/bali.rb", fleet_initializer if initializer == :fleet
    write "app/javascript/controllers/index.js", index_js_fixture(javascript) if javascript
    write "config/importmap.rb", importmap_rb if importmap
    return unless package_json

    write "package.json", named_package_json(package_json)
  end

  def named_package_json(shape)
    case shape
    when :fleet then fleet_package_json
    when :cssbundling then cssbundling_package_json
    else rails_new_package_json
    end
  end

  # garita's file, plus the line gobierno-corporativo added for the engine
  # controllers: the assignment is what "already there" means, whatever the
  # comment around it says.
  def fleet_initializer
    <<~RUBY
      # frozen_string_literal: true

      # Through `config.action_view`, not `ActionView::Base.default_form_builder =`.
      Rails.application.config.action_view.default_form_builder = "Bali::FormBuilder"

      Bali.engine_controller_concerns = [ BaliAuth::EngineAuthentication ]
    RUBY
  end

  def index_js_fixture(shape)
    case shape
    when :fleet then fleet_index_js
    when :identity then identity_index_js
    when :importmap then importmap_index_js
    else rails_new_index_js
    end
  end

  # `rails new` with no --javascript flag, byte for byte what stimulus-rails
  # writes for importmap-rails.
  def importmap_index_js
    <<~JS
      import { application } from "controllers/application"

      import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
      eagerLoadControllersFrom("controllers", application)
    JS
  end

  def importmap_rb
    <<~RUBY
      pin "application"
      pin "@hotwired/turbo-rails", to: "turbo.min.js"
      pin "@hotwired/stimulus", to: "stimulus.min.js"
      pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
      pin_all_from "app/javascript/controllers", under: "controllers"
    RUBY
  end

  def rails_new_index_js
    <<~JS
      import { application } from "./application"

      import HelloController from "./hello_controller"
      application.register("hello", HelloController)
    JS
  end

  # afal-apps, gobierno-corporativo, garita, centinela-web and costa-norte, cut
  # down to the lines that decide anything here.
  def fleet_index_js
    <<~JS
      import { application } from "./application"
      import { registerAll, installConfirmDialog } from "bali-view-components"
      import { registerCharts } from "bali-view-components/charts"

      // Register all Bali Stimulus controllers
      registerAll(application)
      installConfirmDialog({ acceptText: "Aceptar", cancelText: "Cancelar" })
      registerCharts(application)
    JS
  end

  # identity: `registerAll` twice, under two aliases, from esbuild aliases onto
  # paths inside the gem.
  def identity_index_js
    <<~JS
      import { application } from "./application"

      // Register all Bali component controllers from npm package
      import { registerAll as registerComponents } from "bali/components"
      registerComponents(application)

      import { registerAll as registerUtilities } from "bali/controllers"
      registerUtilities(application)

      import { registerCharts } from "bali/charts"
      registerCharts(application)
    JS
  end

  def rails_new_package_json
    JSON.pretty_generate("name" => "host", "private" => true,
                         "dependencies" => { "leftpad" => "1.2.3" })
  end

  # What `rails new --css=tailwind --javascript=esbuild` leaves: the Tailwind build
  # is a package.json script, and there is no tailwindcss:build task anywhere.
  def cssbundling_package_json
    JSON.pretty_generate(
      "name" => "host", "private" => true,
      "scripts" => {
        "build:css" => "tailwindcss -i ./app/assets/stylesheets/application.tailwind.css " \
                       "-o ./app/assets/builds/application.css"
      },
      "dependencies" => { "leftpad" => "1.2.3" }
    )
  end

  # daisyui in devDependencies, where all seven keep it, and the gem pinned a
  # minor behind, where five of them are.
  def fleet_package_json
    JSON.pretty_generate(
      "name" => "host", "private" => true,
      "dependencies" => {
        "@hotwired/stimulus" => "^3.2.2", "@hotwired/turbo-rails" => "^8.0.0",
        "@rails/activestorage" => "^8.0.0", "@rails/request.js" => "^0.0.11",
        "bali-view-components" => "github:Grupo-AFAL/bali-view-components#v3.3.0",
        "date-fns" => "^4.1.0", "lodash.debounce" => "^4.0.8", "lodash.throttle" => "^4.1.1",
        "rrule" => "^2.8.1"
      },
      "devDependencies" => { "daisyui" => "^5.7.0", "esbuild" => "^0.25.0" }
    )
  end

  # The three shared lines in the shape the fleet writes them: a daisyUI block
  # with themes inside it, and the engine bridge already there.
  def fleet_css
    <<~CSS
      @import "tailwindcss";
      @plugin "@tailwindcss/typography";
      @plugin "daisyui" {
        themes: light --default, dark;
      }

      @import "../builds/tailwind/bali";
      @import "bali-view-components/css/bali.css";
      @import "bali-view-components/css/themes/afal.css";

      @custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
    CSS
  end

  def write(path, content)
    full = File.join(destination_root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end
end
