# frozen_string_literal: true

require "test_helper"

# `this.fooTarget?.bar()` reads as "use the target if it is there". It does the opposite.
# The getter Stimulus generates for a SINGULAR target throws when the element is missing —
# stimulus 3.2.2, `dist/stimulus.js:2286-2294`:
#
#   get () { const target = this.targets.find(name)
#            if (target) { return target }
#            else { throw new Error(`Missing target element "${name}" …`) } }
#
# `?.` is evaluated on that getter's RESULT, so it never gets its turn. Written this way the
# code announces "this is optional" and then throws on exactly the case it claims to handle.
# The same lie is spelled `if (this.fooTarget)`, `this.fooTarget && …`, `this.fooTarget ?? …`.
#
# Issue #811: `NavbarController#updateBackgroundColor` was
# `this.burgerTarget?.offsetHeight || this.element.offsetHeight`, and the fallback its author
# wrote was unreachable. A navbar whose only burger is `type: :sidebar` declares no `burger`
# target — `Burger::CONFIGURATIONS[:sidebar]` is empty — so with `transparency: true` every
# throttled scroll event threw and the navbar never left transparent mode. Nothing caught it:
# the component renders a `type: :main` burger as a FALLBACK when the slot is empty, so both
# navbar previews and both dummy layouts have the target and look fine.
#
# A grep and not a lint rule, on purpose. The package lints JS with StandardJS
# (`.githooks/pre-commit`, `.github/workflows/standardjs.yml`), and standard accepts no rule
# configuration by design — one custom rule would mean replacing it with a hand-configured
# ESLint plus a second config and a second CI job. This needs no new dependency and already
# runs where the rest of the suite runs.
class StimulusTargetGuardsTest < ActiveSupport::TestCase
  # Everything the package ships as JS, `app/frontend` included: it is on the npm `files`
  # list like the rest, so a host runs it too.
  SOURCES = Dir[Bali::Engine.root.join("app/**/*.js")].sort.freeze

  # A singular target getter, and NOT its `has…Target` twin — that one is the fix, and it
  # answers a boolean instead of throwing. Plural `fooTargets` is deliberately left alone: it
  # returns `[]` when there is nothing, so `?.` on it is redundant rather than wrong.
  TARGET_GETTER = /this\.(?!has[A-Z])\w+Target\b/

  # `\s*` rather than nothing, because the shape survives a line break: StandardJS wraps a
  # long expression and the `?.` lands on the next line, where a single-line grep misses it.
  UNSAFE_SHAPES = Regexp.union(
    /#{TARGET_GETTER}\s*(?:\?\.|\?\?)/,
    /if\s*\(\s*!?\s*#{TARGET_GETTER}\s*\)/,
    /#{TARGET_GETTER}\s*(?:&&|\|\|)/
  )

  def test_no_shipped_controller_treats_a_target_getter_as_optional
    offenders = []

    SOURCES.each do |path|
      source = blank_out_comments(File.read(path))

      source.scan(UNSAFE_SHAPES) do
        line = source[0...Regexp.last_match.begin(0)].count("\n") + 1
        relative = path.delete_prefix("#{Bali::Engine.root}/")
        offenders << "#{relative}:#{line}: #{Regexp.last_match[0].squish}"
      end
    end

    assert_empty(offenders, <<~MESSAGE)
      A Stimulus target getter is being treated as if it could be missing:

        #{offenders.join("\n        ")}

      It cannot be — it throws. Ask the `has…Target` twin first:

        this.fooTarget?.focus()        ->  if (this.hasFooTarget) this.fooTarget.focus()
        this.fooTarget?.h || fallback  ->  (this.hasFooTarget && this.fooTarget.h) || fallback
        if (this.fooTarget)            ->  if (this.hasFooTarget)

      If the target is NOT optional, drop the guard entirely and let it throw loudly.
    MESSAGE
  end

  private

  # Comments are where this pattern gets WRITTEN OUT rather than committed — every fix in
  # #811 explains itself by quoting the shape it replaced, and the grep cannot tell the
  # quotation from the crime.
  #
  # Only whole-line `//` comments and `/* … */` blocks go, never a trailing `//`: stripping
  # from a `//` in the middle of a line would also eat a `'https://…'` and, with it, any real
  # violation sitting after it. Blanking rather than deleting keeps the line numbers honest.
  def blank_out_comments(source)
    source
      .gsub(%r{/\*.*?\*/}m) { |block| block.gsub(/[^\n]/, " ") }
      .gsub(%r{^[ \t]*//.*$}) { |line| " " * line.length }
  end
end
