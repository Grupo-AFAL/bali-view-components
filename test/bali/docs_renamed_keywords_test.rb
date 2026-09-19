# frozen_string_literal: true

require "test_helper"

# A renamed keyword the guide still teaches fails LOUDLY, but late and in the wrong place: the
# host copies the example, the component raises `ArgumentError`, and the only thing they have to
# understand it with is the very page that just recommended it. That was #1159: the WorkflowSteps
# section offered `Component.new(variant: :horizontal)` — character for character the call
# test/bali/components/workflow_steps_test.rb uses to prove the guard blows up — while the Stepper
# section, twenty-six lines above it, already said `orientation:`.
#
# The components' guards are half a promise: they tell the new name to whoever already got it
# wrong. This test is the other half: what the gem rejects at runtime, the documentation does not
# offer.
#
# WHAT IT CATCHES, EXACTLY. It recognises SHAPES, not intentions. Offering a keyword and naming a
# rename are different things —this very correction writes "It was `variant:` in the v3.1 betas",
# which has to stay green— so each keyword is looked for in the concrete shapes the documentation
# hands it out in: the call, the `keyword: value` and the options bullet that heads it. A rejected
# keyword mentioned any other way does not trip it, and that is the line this test can hold: it
# does not promise "no use", it promises "none of these shapes".
class BaliDocsRenamedKeywordsTest < ActiveSupport::TestCase
  ENGINE_ROOT = Pathname.new(File.expand_path("../..", __dir__))
  DOCS_GLOB = ENGINE_ROOT.join("docs/**/*.md").to_s

  # The migration guide is the exception, and that is its whole reason to exist: it documents every
  # rename with the `<%# beta %>` / `<%# now %>` pair, so the old keyword HAS to appear there.
  MIGRATION_GUIDE = ENGINE_ROOT.join("docs/guides/migration-v3-to-v31.md").to_s

  # `docs/` is not all the documentation a host reads. The README is their first page, and the
  # annotations in the `preview.rb` files are prose Lookbook serves to the same reader — the very
  # sentence this PR corrects came down from one of them, so they are the guide's upstream, not an
  # extra.
  SOURCES = (
    Dir[DOCS_GLOB] +
    [ ENGINE_ROOT.join("README.md").to_s ] +
    Dir[ENGINE_ROOT.join("app/components/bali/**/preview.rb").to_s]
  ).sort.freeze

  PROSE = (SOURCES - [ MIGRATION_GUIDE ]).freeze

  # Each entry is a keyword the gem rejects TODAY with a guard of its own, so an example using it is
  # not dated: it is broken. `rename` names the replacement and the file the guard lives in, which
  # is what to read when this test fails; `shapes` are the ways of handing it out, named so the
  # failure says which one slipped through.
  #
  # The call patterns accept the keyword in ANY position (`[^)]*`): in #1159 the WorkflowSteps one
  # demanded it be the first argument, and `new(progress: false, variant: :horizontal)` escaped it.
  REJECTED = [
    {
      rename: "`variant:` → `orientation:` (app/components/bali/workflow_steps/component.rb)",
      shapes: {
        "la llamada" => /WorkflowSteps::Component\.new\([^)]*\bvariant:/,
        # No Bali component takes `variant:` with these values —we looked: the axis is called
        # `orientation:` in every one of them— so this shape can only be the renamed keyword,
        # whether it comes in prose or inside an example.
        "el keyword con su valor" => /\bvariant:\s*:(?:vertical|horizontal)\b/,
        # The options bullet: it is what somebody learning the API skims, before reaching the code
        # block. `variant` heading a bullet that documents orientation values is not ambiguous;
        # Button's or Pagination's `variant` lists colours.
        "la viñeta de opciones" => /^[ \t]*[-*][ \t]*`variant`[^\n]*`:(?:vertical|horizontal)`/
      }
    },
    {
      rename: "`label:` → `aria_label:` (app/components/bali/topbar/icon_action/component.rb)",
      # The call only: the value is a free string and `label:` is a legitimate keyword in half the
      # library, so outside the component's parentheses there is no way to tell the rejected one
      # from the good one without false positives.
      shapes: { "la llamada" => /IconAction::Component\.new\([^)]*\blabel:/ }
    },
    {
      rename: "`search_label:` → `search_aria_label:` (lib/bali/filter_form.rb)",
      shapes: { "el keyword" => /\bsearch_label:/ }
    },
    {
      rename: "search_fields `label:` → `aria_label:` (lib/bali/filter_form/search_configuration.rb)",
      # `\b` does not bite inside `aria_label:` —the underscore is a word character— so the good
      # name does not fire.
      shapes: { "la llamada del DSL" => /search_fields[^\n]*\blabel:/ }
    }
  ].freeze

  # If the exception's path is misspelled, or the glob returns it normalised some other way, the
  # subtraction removes nothing and the test goes green the stupid way: it would keep passing, but
  # would stop guarding the migration guide. `assert_includes` over the glob is what actually ties
  # the two spellings of the file together; subtracting it from a list that contains it by
  # construction proves nothing.
  def test_the_migration_guide_is_actually_excluded
    assert_path_exists(MIGRATION_GUIDE)
    assert_includes(Dir[DOCS_GLOB], MIGRATION_GUIDE)
    assert_not_includes(PROSE, MIGRATION_GUIDE)
    assert_equal(SOURCES.size - 1, PROSE.size)
    assert_not_empty(PROSE)
  end

  def test_the_documentation_offers_no_keyword_the_components_reject
    hits = PROSE.flat_map do |path|
      content = File.read(path)
      relative = Pathname.new(path).relative_path_from(ENGINE_ROOT)

      REJECTED.flat_map do |keyword|
        keyword[:shapes].flat_map do |shape, pattern|
          content.to_enum(:scan, pattern).map do
            line = content[0, Regexp.last_match.begin(0)].count("\n") + 1
            [ "#{relative}:#{line}", keyword[:rename], shape ]
          end
        end
      end
    end

    # One single line can be caught by two shapes at once —#1159's copyable example is the call AND
    # the `keyword: value`—: that is one place to fix, not two.
    offenders = hits.group_by { |where, rename, _| [ where, rename ] }.map do |(where, rename), group|
      "  #{where} — #{rename} [#{group.map(&:last).join(', ')}]"
    end.sort

    assert_empty(
      offenders,
      "La documentación ofrece keywords que la gema rechaza. Un host que copie el ejemplo " \
      "no obtiene una advertencia: obtiene un ArgumentError.\n" + offenders.join("\n")
    )
  end
end
