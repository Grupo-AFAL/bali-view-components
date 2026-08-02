# frozen_string_literal: true

require "test_helper"

# A `render Bali::X::Component.new(foo: 1)` where the component does not declare `foo:` does
# not raise: every component ends its signature in `**options` and forwards the leftovers to
# the outer tag, so the keyword comes out as a literal `foo="1"` HTML attribute and whatever
# the caller meant by it silently does not happen.
#
# Nothing catches that shape. A grep cannot, because the mistake is the *absence* of a
# keyword from a signature written somewhere else. The suite cannot, because the page still
# renders. A sweep of the served pages cannot either, which is the part worth internalising:
# a page that renders less than it should answers 200 just as happily as a correct one —
# #781 and #787 were both found by reading the DOM by hand, not by anything automated.
#
# So this compares, by reflection, the keywords of every `Bali::X::Component.new` call in the
# dummy's views against the `initialize` parameters of the whole ancestor chain. Walking the
# chain rather than the class is not optional: `FormPage` declares `card:` and inherits
# `title:`/`subtitle:`/`breadcrumbs:`/`back:`/`max_width:` from `PageComponents::Shared`
# through `super`, and looking only at the class reports six calls that are perfectly fine.
class DummyComponentKeywordsTest < ActiveSupport::TestCase
  VIEWS = Rails.root.join("app/views")

  OPENERS = "([{"
  CLOSERS = ")]}"
  QUOTES = "'\""

  # Keywords any component may legitimately be handed without declaring them: they are HTML
  # attributes on the outer tag, which is exactly what `**options` is for. Kept to attributes
  # that are global HTML (or, for `rel`/`target`/`form`, generic to the tag the component
  # renders) — deliberately NOT `name:` or `value:`, which are component API often enough
  # that listing them here would hide the very mistake this looks for. Hyphenated keys are
  # written quoted (`'aria-label':`) and the scanner skips string literals, so the whole
  # `aria-*` and `data-*` families never reach this list.
  PASSTHROUGH = %w[
    class data id style title role rel target form hidden lang dir tabindex
  ].freeze

  # Components that read keys out of `**options` on purpose rather than declaring them. This
  # is real API — the component would behave differently without them — so a call site using
  # one is correct and must not be reported.
  #
  # Every entry needs its reason, and the list is meant to stay short. A sweep whose
  # allowlist absorbs whatever it complains about stops being worth running, so the answer to
  # a new finding is almost always to fix the call site or to declare the keyword on the
  # component; this is for the case where the component genuinely reads `options[:foo]`.
  #
  # Each list below was read off the component's source, not assumed: every entry
  # corresponds to an `options[:key]` in the file named beside it.
  KNOWN_OPTION_READERS = {
    # app/components/bali/data_table/component.rb. `item_name:` and `display_mode:` even
    # carry `@param` docs (lines 300-304) while being read from `options` — this is the
    # component the issue singled out as the reason the allowlist has to exist.
    "Bali::DataTable::Component" => %w[
      combinator display_mode filter_groups icon_only item_name persist_enabled
      persistence_toggle preserved_params storage_id summary_position table_class view_param
    ]
  }.freeze

  def test_no_dummy_view_passes_a_keyword_its_component_does_not_declare
    findings = calls.filter_map do |call|
      undeclared = undeclared_keywords(call)
      next if undeclared.empty?

      "#{call[:file]}:#{call[:line]}  #{call[:component]}  ->  #{undeclared.join(", ")}"
    end

    assert_empty findings, <<~MESSAGE
      These calls pass keywords the component does not declare. Each one renders as a
      literal HTML attribute and does nothing:

      #{findings.join("\n")}

      Fix the call site. If the keyword really is API the component reads out of
      `**options`, add it to KNOWN_OPTION_READERS with the reason.
    MESSAGE
  end

  # The sweep is worthless if it silently stops finding call sites — a change to the render
  # syntax, a views directory that moves, a regex that stops matching. This pins that it is
  # still looking at something.
  def test_the_sweep_still_finds_the_call_sites
    assert_operator calls.size, :>=, 100,
      "the sweep found only #{calls.size} component calls in #{VIEWS}; it has probably " \
      "stopped matching rather than the dummy having shrunk"
  end

  private

  def calls
    @calls ||= Dir.glob(VIEWS.join("**/*.erb")).sort.flat_map { |file| calls_in(file) }
  end

  def calls_in(file)
    source = File.read(file)
    source.enum_for(:scan, /Bali::([A-Za-z0-9_:]+?)::Component\.new\(/).filter_map do
      open_paren = Regexp.last_match.end(0) - 1
      args = balanced_arguments(source, open_paren)
      next if args.nil?

      {
        file: Pathname.new(file).relative_path_from(Rails.root).to_s,
        line: source[0...open_paren].count("\n") + 1,
        component: "Bali::#{Regexp.last_match(1)}::Component",
        keywords: top_level_keywords(args)
      }
    end
  end

  # Returns the text between the `new(` and its matching `)`, or nil if the call splices a
  # hash (`**opts`) and so has no keywords this can read.
  def balanced_arguments(source, open_paren)
    depth = 0
    quote = nil
    index = open_paren

    while index < source.length
      char = source[index]
      if quote
        quote = nil if char == quote && source[index - 1] != "\\"
      elsif QUOTES.include?(char)
        quote = char
      elsif OPENERS.include?(char)
        depth += 1
      elsif CLOSERS.include?(char)
        depth -= 1
        return source[(open_paren + 1)...index] if depth.zero?
      end
      index += 1
    end

    nil
  end

  # Keywords written at the top level of the argument list. The colon has to sit flush
  # against the identifier: `color: done? ? :success : :warning` would otherwise report
  # `success`, which is the ternary artefact that made the original hand-run sweep noisy.
  def top_level_keywords(args)
    depth = 0
    quote = nil
    keywords = []
    index = 0

    while index < args.length
      char = args[index]
      if quote
        quote = nil if char == quote && args[index - 1] != "\\"
      elsif QUOTES.include?(char)
        quote = char
      elsif OPENERS.include?(char)
        depth += 1
      elsif CLOSERS.include?(char)
        depth -= 1
      elsif depth.zero? && !preceded_by_word_char?(args, index) &&
            (match = args[index..].match(/\A([a-z_][A-Za-z0-9_]*):(?![:\w])/))
        keywords << match[1]
        index += match[0].length - 1
      end
      index += 1
    end

    keywords
  end

  # `:success` in `color: done? ? :success : :warning`, and the `bar` of `foo.bar:`, are not
  # keywords. Anchoring the scan's regex to a substring cannot see what precedes it, so the
  # preceding character is checked here.
  def preceded_by_word_char?(args, index)
    index.positive? && args[index - 1].match?(/[:\w.]/)
  end

  def undeclared_keywords(call)
    component = call[:component].safe_constantize
    return [] if component.nil?

    known = declared_keywords(component) +
      PASSTHROUGH +
      KNOWN_OPTION_READERS.fetch(call[:component], [])

    call[:keywords].uniq - known
  end

  # Every `initialize` in the chain, not just the class's own: a component that inherits its
  # keywords through `super` declares them in an ancestor.
  def declared_keywords(component)
    component.ancestors.flat_map { |mod| initialize_keywords(mod) }.uniq
  end

  def initialize_keywords(mod)
    return [] unless mod.private_instance_methods(false).include?(:initialize) ||
      mod.instance_methods(false).include?(:initialize)

    mod.instance_method(:initialize).parameters.filter_map do |type, name|
      name.to_s if %i[key keyreq].include?(type)
    end
  rescue NameError
    []
  end
end
