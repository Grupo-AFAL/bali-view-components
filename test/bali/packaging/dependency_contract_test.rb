# frozen_string_literal: true

require "test_helper"

# What a host is made to load and what the gemspec promises have to be the same list.
#
# The failure mode is not a missing feature, it is a host that does not boot, and
# it arrives on an unrelated day: `csv` stopped being a default gem in Ruby 3.4,
# which turned the unconditional `require "csv"` in
# `lib/bali/commands/csv_export.rb` into a boot crash in every application that
# had not written `gem "csv"` in its own Gemfile. All seven apps in the fleet
# carry those lines by hand today, one of them under the comment "Required by
# Bali" — a dependency the gem declined to declare.
#
# "MADE TO LOAD" IS BIGGER THAN `lib/`. `lib/bali/engine.rb` assigns
# `config.eager_load_paths`, so in production every file under those six `app/`
# directories loads at boot too. The first version of this test walked `lib/`
# only, and passed while `app/components/bali/pagination/pagy_adapter.rb` opened
# with an unguarded `require "pagy/..."` and
# `app/components/bali/application_view_component_preview.rb` with
# `include Pagy::Method` — the exact bug #1139 exists to close, still live, on a
# gem the gemspec does not ask for. Both halves are covered below: what a file
# `require`s, and what it needs in order to be DEFINED.
#
# The gemspec is `bali_view_component.gemspec`, SINGULAR, while the gem it
# defines is `bali_view_components`, plural, and the Gemfile's comment calls it
# `bali.gemspec`. Three spellings, one file: resolve it by globbing rather than
# by name, or a test that loads the wrong path passes by finding nothing.
class BaliDependencyContractTest < ActiveSupport::TestCase
  ROOT = Bali::Engine.root

  # A require path is not always a gem name.
  GEM_FOR_REQUIRE = {
    "active_support" => "activesupport",
    "active_record" => "activerecord",
    "active_model" => "activemodel",
    "action_view" => "actionview",
    "action_controller" => "actionpack",
    "diff/lcs" => "diff-lcs"
  }.freeze

  # `rails` is declared, and it is what brings these in.
  RAILS_COMPONENTS = %w[
    actionpack actionview activejob activemodel activerecord activestorage
    activesupport railties
  ].freeze

  INSTALL_DOCS = %w[README.md docs/guides/installation.md].freeze

  # A name every interpreter can load, to prove the child process below answered
  # at all instead of exempting nothing for the wrong reason.
  SENTINEL = "stringio"
  CLEAN_ENV = { "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil, "RUBYLIB" => nil }.freeze

  def test_the_gemspec_is_findable_and_singular
    assert_equal "bali_view_component.gemspec", File.basename(gemspec_path),
                 "the gemspec is singular while the gem is plural; a test that hardcodes " \
                 "the plural spelling loads nothing and passes for the wrong reason"
    assert_equal "bali_view_components", gemspec.name
  end

  # The contract. Every gem reached by an unguarded, top-level `require` on the
  # boot path is a gem the host must have, so it is a gem this gemspec has to ask
  # for. A `require` that is indented — inside a `begin/rescue LoadError`, inside
  # a method, under a `defined?` — is an optional dependency and is none of this
  # test's business (see `rrule` below, `rqrcode` in qr_code_test.rb, and the
  # `require` that now sits inside `PagyAdapter#series`).
  def test_every_gem_required_at_boot_is_declared_in_the_gemspec
    undeclared = boot_requires.reject { |gem_name, _| declared?(gem_name) }

    assert_empty undeclared.transform_values { |files| files.sort.join(", ") },
                 "these gems are required unconditionally while Bali boots but are not in " \
                 "#{File.basename(gemspec_path)}. Either add `spec.add_dependency`, or make " \
                 "the require optional the way Bali::QrCode::Component does with rqrcode."
  end

  # The other half of the same boot: a file does not have to `require` a gem to
  # need it. `include Pagy::Method` in the class body of a file `eager_load_paths`
  # covers is a NameError at boot in a host without pagy, and no scan of `require`
  # lines can see it.
  #
  # The owning gem is MEASURED — `const_source_location`, then the gem whose
  # directory that file sits in — never listed here: a hand-kept list is the
  # mistake this whole test exists to undo. A constant Zeitwerk defines belongs to
  # Bali's own tree or the host's, and one that does not resolve at top level is a
  # relative reference inside Bali; neither can come from a gem.
  def test_nothing_the_host_eager_loads_needs_an_undeclared_gem_to_define_itself
    offenders = mixed_in_constants.filter_map do |constant, sites|
      gem_name = gem_owning(constant)
      next if gem_name.nil? || declared?(gem_name)

      [ "#{constant} (gem #{gem_name})", sites.uniq.sort.join(", ") ]
    end.to_h

    assert_empty offenders,
                 "these files are eager-loaded in a host — lib/bali/engine.rb assigns " \
                 "config.eager_load_paths — and name a constant from a gem the gemspec does " \
                 "not declare, so merely defining the class raises NameError during boot. " \
                 "Declare the gem, move the reference inside a method, or keep the file out " \
                 "of the eager load through Bali::Engine::NOT_EAGER_LOADED."
  end

  # The other half of the same contract, and the reason `rrule` is NOT declared:
  # an override whose only job is to patch a class from a gem the host chose to
  # install has to be inert when that gem is absent. It is `load`ed on every
  # `to_prepare`, so an unguarded `RRule::Rule.class_eval` is a NameError during
  # boot — in an application that may never render a recurrence rule.
  def test_the_rrule_override_is_inert_without_the_gem
    override = ROOT.join("lib/bali/overrides/rrule_override.rb")
    rrule = Object.send(:remove_const, :RRule) if defined?(RRule)

    begin
      load override

      assert_nil defined?(RRule), "the guard has to skip the patch, not define the constant itself"
    rescue NameError => e
      flunk "#{override.basename} needs RRule to exist merely to be loaded (#{e.message}). " \
            "A host without the gem crashes on boot, before it could learn which gem to add."
    ensure
      Object.const_set(:RRule, rrule) if rrule
    end
  end

  # The rescue branch, actually taken. With rrule in the bundle, `require "rrule"`
  # in the override returns false and the `rescue LoadError` never runs, so the
  # test above only ever exercised the `defined?` half. A child interpreter with
  # RubyGems switched off has no rrule and no pagy at all, which is the closest
  # thing to a host that never installed them — and these two files are the ones
  # that reach for a gem the gemspec does not declare.
  def test_the_files_that_touch_an_undeclared_gem_still_load_when_it_is_absent
    %w[lib/bali/overrides/rrule_override.rb
       app/components/bali/pagination/pagy_adapter.rb].each do |relative|
      out = IO.popen([ CLEAN_ENV, RbConfig.ruby, "--disable-gems", "-e",
                       "load ARGV[0]; print 'loaded'", ROOT.join(relative).to_s ],
                     err: [ :child, :out ], &:read)

      assert_equal "loaded", out,
                   "#{relative} does not survive a host without the gem it reaches for, which " \
                   "is a boot crash: lib/bali/engine.rb eager-loads app/components, and the " \
                   "engine loads every override on each to_prepare"
    end
  end

  # ...and with the gem present it still patches, or the guard bought silence
  # instead of safety.
  def test_the_rrule_override_still_teaches_humanize_when_the_gem_is_there
    load ROOT.join("lib/bali/overrides/rrule_override.rb")

    rule = RRule::Rule.new("FREQ=WEEKLY;BYDAY=MO")

    assert_respond_to rule, :humanize
    assert_not_empty rule.humanize(:es)
  end

  # Bali installs from a git tag, so the tag in the install instructions IS the
  # version the reader gets. Nothing kept the two in sync: the README sat on
  # `v3.1.0.beta.13` for four releases, which hands a reader a different library
  # from the one they are reading about.
  #
  # TWO SPELLINGS, AND EACH ONE HAS TO BE FOUND. A scan that matches nothing
  # rejects nothing and this test goes green while the docs rot: measured — with
  # the README's `tag:` rewritten as `ref:`, the previous version of this test
  # passed on `v3.1.0.beta.13`. The second spelling is the console transcript
  # under § Verification, which went stale the same way and out of reach of the
  # first regex.
  VERSION_SPELLINGS = [
    { what: "the tag to install", docs: INSTALL_DOCS, prefix: "v",
      pattern: /bali-view-components["#,\s]+tag:\s*"([^"]+)"/ },
    { what: "the version the console prints back", docs: %w[docs/guides/installation.md],
      prefix: "", pattern: /^=> "(\d[^"]*)"/ }
  ].freeze

  def test_the_install_instructions_pin_this_version
    VERSION_SPELLINGS.each do |spelling|
      spelling[:docs].each do |relative|
        found = ROOT.join(relative).read.scan(spelling[:pattern]).flatten
        expected = "#{spelling[:prefix]}#{Bali::VERSION}"

        assert_not_empty found, "#{relative} no longer spells #{spelling[:what]}, so this test " \
                                "has stopped checking it there"
        assert_equal [ expected ], found.uniq,
                     "#{spelling[:what]} has to be #{expected} in #{relative}"
      end
    end
  end

  private

  def gemspec_path
    @gemspec_path ||= Dir[ROOT.join("*.gemspec").to_s].sole
  end

  def gemspec
    @gemspec ||= Gem::Specification.load(gemspec_path)
  end

  def declared?(gem_name)
    return true if interpreter_provides.include?(gem_name)
    return true if RAILS_COMPONENTS.include?(gem_name) && declared_names.include?("rails")

    declared_names.include?(gem_name)
  end

  def declared_names
    @declared_names ||= gemspec.runtime_dependencies.map(&:name)
  end

  # MEASURED, not listed. What stood here was a hand-written DEFAULT_GEMS array
  # under the comment "part of the interpreter, impossible to uninstall" — the
  # exact belief that shipped the `csv` bug, and already rotten: `benchmark` left
  # the default gems in Ruby 4.0.0 and the array still exempted it.
  #
  # So ask this interpreter instead, in one child process with RubyGems switched
  # off. What survives `--disable-gems` is stdlib, builtin or a default gem — that
  # is, something no Gemfile can take away. A gem Ruby merely BUNDLES (`csv`,
  # `benchmark`) fails there, which is the whole point.
  def interpreter_provides
    @interpreter_provides ||= begin
      names = boot_requires.keys | [ SENTINEL ]
      # `rescue LoadError` spelled out: a modifier rescue catches StandardError, and a
      # missing gem raises ScriptError, so `require name rescue false` crashes the child.
      script = "puts ARGV.select { |name| begin; require name; true; rescue LoadError; false; end }"
      answer = IO.popen([ CLEAN_ENV, RbConfig.ruby, "--disable-gems", "-e", script, *names ],
                        err: File::NULL, &:read).split("\n").to_set

      assert_includes answer, SENTINEL,
                      "the child interpreter answered nothing, so every require would look " \
                      "undeclared for the wrong reason"
      answer
    end
  end

  # Every file Ruby reads to boot this engine inside a host, followed the way Ruby
  # follows it: from `lib/bali.rb` and `lib/bali/engine.rb` through their
  # unindented `require`s, the overrides `engine.rb` loads by glob on every
  # prepare, and everything `config.eager_load_paths` reaches.
  def boot_requires
    @boot_requires ||= begin
      external = Hash.new { |hash, key| hash[key] = [] }
      visited = Set.new
      queue = [ ROOT.join("lib/bali.rb"), ROOT.join("lib/bali/engine.rb"),
                *Dir[ROOT.join("lib/bali/overrides/*.rb").to_s].map { |path| Pathname(path) },
                *eager_load_surface ]

      while (path = queue.shift)
        next unless path.exist? && visited.add?(path.to_s)

        each_unguarded_require(path) do |required, relative|
          if (internal = internal_path(required, path, relative))
            queue << internal
          else
            external[gem_name_for(required)] << path.relative_path_from(ROOT).to_s
          end
        end
      end

      external
    end
  end

  # From the engine's own config, minus the engine's own exclusions, so this test
  # cannot drift from what a host is actually made to load.
  def eager_load_surface
    @eager_load_surface ||= begin
      excluded = Bali::Engine::NOT_EAGER_LOADED
        .flat_map { |pattern| Dir[ROOT.join(pattern).to_s] }.to_set

      Bali::Engine.config.eager_load_paths
        .flat_map { |directory| Dir["#{directory}/**/*.rb"] }
        .reject { |file| excluded.include?(file) }
        .map { |file| Pathname(file) }
    end
  end

  # `include Foo`, `extend Foo`, `prepend Foo` and `class Bar < Foo` at class-body
  # level: the references that run the moment the file is loaded.
  MIXIN = /^\s*(?:(?:include|extend|prepend)\s+((?:::)?[A-Z][\w:]*)
              |class\s+[\w:]+\s*<\s*((?:::)?[A-Z][\w:]*))/x

  def mixed_in_constants
    @mixed_in_constants ||= eager_load_surface.each_with_object(
      Hash.new { |hash, key| hash[key] = [] }
    ) do |path, found|
      path.each_line do |line|
        next if line.lstrip.start_with?("#")
        next unless (match = MIXIN.match(line))

        found[(match[1] || match[2]).delete_prefix("::")] << path.relative_path_from(ROOT).to_s
      end
    end
  end

  def gem_owning(constant)
    source = begin
      Object.const_source_location(constant)&.first
    rescue NameError
      nil
    end
    return nil if source.nil?

    spec = Gem.loaded_specs.values.find { |loaded| source.start_with?(loaded.full_gem_path) }
    return nil if spec.nil? || [ "zeitwerk", gemspec.name ].include?(spec.name)

    spec.name
  end

  def each_unguarded_require(path)
    path.each_line do |line|
      match = /\A(require(?:_relative)?)\s+["']([^"']+)["']\s*\z/.match(line.rstrip)
      yield match[2], match[1] == "require_relative" if match
    end
  end

  def internal_path(required, from, relative)
    return from.dirname.join("#{required}.rb") if relative
    return ROOT.join("lib", "#{required}.rb") if required == "bali" || required.start_with?("bali/")

    nil
  end

  def gem_name_for(required)
    return GEM_FOR_REQUIRE[required] if GEM_FOR_REQUIRE.key?(required)

    top = required.split("/").first
    GEM_FOR_REQUIRE.fetch(top, required.include?("/") ? top : required)
  end
end
