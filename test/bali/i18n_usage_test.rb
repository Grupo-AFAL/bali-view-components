# frozen_string_literal: true

require "test_helper"

# Every `bali_view.*` key the library ASKS for has to exist — in both locales.
#
# `i18n_scope_test.rb` compares the two YAML files against each other, so it
# catches a key translated into one locale and not the other. It cannot catch
# the other direction: a component asking for a key that was never written down.
# That one renders the humanized key ("Some Missing Key") to the visitor, or the
# `default:` the call site carries, and nothing fails.
#
# THE RULE THIS ENCODES (from the audit that produced it):
#
#   `default:` on somebody else's key — `number.*`, `activerecord.*`, a host's
#   own scope — is depending correctly on another namespace, and stays.
#   `default:` on OUR OWN `bali_view.*` key is hiding that the string is
#   missing.
#
# Which is why the filter is BY PREFIX rather than a list of exceptions: an
# allowlist of "keys we know are foreign" needs editing every time a component
# reaches for a Rails built-in, and rots into a list nobody trusts. Everything
# under `bali_view.` is ours and must exist; everything else is a dependency and
# is not this test's business.
#
# With this guard in place a `default:` on a Bali key can simply be deleted: if
# the string ever goes missing, the suite goes red here instead of the component
# quietly rendering something hardcoded.
class BaliI18nUsageTest < ActiveSupport::TestCase
  ROOT = Bali::Engine.root

  # Where Bali asks for strings. `spec/dummy` is a host app, not the library.
  SOURCES = [ "app/components/**/*.rb", "app/components/**/*.erb", "lib/bali/**/*.rb" ].freeze

  # Keys under this prefix are Bali's own and must exist. See the header.
  OWN_PREFIX = "bali_view."

  # Single-quoted so Ruby leaves it alone: this is the literal `#{` that opens
  # an interpolation inside the source being SCANNED.
  INTERPOLATION = '#{'

  # `t(...)`, `I18n.t(...)`, `helpers.t(...)`. The lookbehind keeps the bare
  # form from matching the tail of an identifier (`format(`, `assert(`) or a
  # method on some other object (`presenter.t(`).
  CALL = /(?:I18n\.t|helpers\.t|(?<![\w.:])t)\(/

  # The first argument, when it is a literal: "...", '...', :"..." or :name.
  # Anything else (a variable, a method call) leaves nothing static to check.
  KEY_LITERAL = /\A\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'|:"((?:[^"\\]|\\.)*)"|:([A-Za-z_]\w*[?!]?))/

  def test_every_bali_key_a_component_asks_for_exists_in_both_locales
    en = flatten(locale_file("en"))
    es = flatten(locale_file("es"))

    missing = lookups.filter_map do |lookup|
      absent = []
      absent << "en" unless resolves?(lookup[:key], en)
      absent << "es" unless resolves?(lookup[:key], es)
      next if absent.empty?

      "#{lookup[:file]}:#{lookup[:line]} → #{lookup[:key]} (falta en #{absent.join(' y ')})"
    end

    assert_equal [], missing,
                 "claves de bali_view que un componente pide y no existen:\n  " +
                 missing.join("\n  ")
  end

  # A guard that stopped finding anything would pass forever, so the sweep has
  # to prove it swept. A count rather than a key name: naming one makes the test
  # fail as "the scanner is broken" the day somebody renames that string.
  def test_the_sweep_is_not_vacuous
    assert_operator lookups.size, :>, 100,
                    "el escáner dejó de encontrar llamadas: revisa CALL/SOURCES"
  end

  # The parser, against a fixture instead of the repo — every shape the codebase
  # actually uses, so a refactor that breaks one fails HERE, naming it, instead
  # of silently shrinking what the guard above covers.
  def test_the_scanner_understands_the_call_shapes_the_codebase_uses
    source = <<~RUBY
      # Doc comments quote real call sites: t(".from_a_comment") must not count.
      def labels
        yes_no = flag ? I18n.t("bali_view.filters.yes") : I18n.t(
                                        "bali_view.filters.no")
        relative = t(".relative_key")
        nested = link_to(t(".inside_a_call"), href)
        tail = I18n.t("bali_view.filters.operators.\#{key}")
        whole = I18n.t("\#{scope}.\#{value}")
        foreign = I18n.t("number.human.storage_units", default: "KB")
        dynamic = I18n.t(some_variable)
        symbol = t(:"bali_view.filters.title")
      end
    RUBY

    keys = lookups_in_source(source, scope: "bali_view.demo", file: "demo.rb").map { |l| l[:key] }

    # Multi-line, and inside another call — the reason this scans the source and
    # not one line at a time.
    assert_includes keys, "bali_view.filters.no"
    assert_includes keys, "bali_view.demo.inside_a_call"
    # Relative keys hang off the component's own scope.
    assert_includes keys, "bali_view.demo.relative_key"
    # Interpolation in the tail degrades to the static parent scope...
    assert_includes keys, "bali_view.filters.operators"
    # ...and a key interpolated from the start has nothing to check.
    refute_includes keys, "bali_view.filters.title.\#{value}"
    # A symbol key is still a key.
    assert_includes keys, "bali_view.filters.title"
    # THE design decision: foreign namespaces are a dependency, not our debt.
    refute_includes keys, "number.human.storage_units"
    assert_empty keys.grep(/from_a_comment/), "el escáner leyó un comentario"
    assert_empty keys.grep(/some_variable/), "el escáner inventó una clave dinámica"
  end

  private

  # [{ file:, line:, key: }] — every Bali key asked for anywhere in the library,
  # already resolved to its absolute form.
  def lookups
    @lookups ||= files.flat_map { |path| lookups_in(path) }
  end

  def files
    SOURCES.flat_map { |glob| Dir[ROOT.join(glob)] }.sort
  end

  def lookups_in(path)
    lookups_in_source(File.read(path), scope: scope_for(path), file: relative(path),
                      erb: path.end_with?(".erb"))
  end

  # Scans the SOURCE, not line by line: a key can sit on a continuation line,
  # and in this codebase one sits on a continuation line *inside another call*
  # (`filters/applied_tags`). Comments go first — see strip_comments.
  def lookups_in_source(raw, scope:, file:, erb: false)
    source = strip_comments(raw, erb: erb)

    source.enum_for(:scan, CALL).filter_map do
      offset = Regexp.last_match.end(0)
      key = resolve(literal_at(source, offset), scope)
      next unless key&.start_with?(OWN_PREFIX)

      { file: file, line: source[0...offset].count("\n") + 1, key: key }
    end
  end

  def literal_at(source, offset)
    match = KEY_LITERAL.match(source[offset, 200].to_s)
    match && (match[1] || match[2] || match[3] || match[4])
  end

  # Relative keys (`.foo`) hang off the component's own scope, which is its
  # path under app/components/bali (`split_view/list` → `bali_view.split_view.list`)
  # — the same rule ViewComponent's `virtual_path` applies at runtime.
  #
  # A key whose interpolation is in the TAIL (`display_modes.#{mode}`) still has
  # a static parent worth checking, so it degrades to that scope. One that is
  # interpolated from the start (`"#{scope}.#{value}"`) has nothing to check.
  def resolve(literal, scope)
    return nil if literal.nil? || literal.start_with?(INTERPOLATION)

    relative = literal.start_with?(".")
    return nil if relative && scope.nil? # lib/ has no component scope to hang it off

    key = relative ? "#{scope}#{literal}" : literal
    static, interpolated = key.split(INTERPOLATION, 2)
    return static if interpolated.nil?

    static.rpartition(".").first.presence
  end

  def scope_for(path)
    relative = relative(path)
    return nil unless relative.start_with?("app/components/bali/")

    segments = relative.delete_prefix("app/components/bali/").split("/")[0..-2]
    [ OWN_PREFIX.chomp("."), *segments ].join(".")
  end

  # A key resolves when it names a string OR a scope that holds them — the
  # parent-scope case above lands on the latter.
  def resolves?(key, table)
    table.key?(key) || table.keys.any? { |candidate| candidate.start_with?("#{key}.") }
  end

  # Doc comments in this repo are long and quote real call sites (`t(".label")`
  # inside a `#` block is common), so they have to go before scanning or the
  # test invents lookups nothing performs. Both substitutions preserve newlines,
  # which is what keeps the reported line numbers honest.
  #
  # Deliberately conservative: a line with a quote before the `#` is left alone
  # rather than risk cutting inside a string. A `t(...)` in a TRAILING comment on
  # such a line would still be read — it has not happened, and the cost of that
  # being wrong is a named failure, not a silent pass.
  def strip_comments(source, erb:)
    source = source.gsub(/<%#.*?%>/m) { |block| "\n" * block.count("\n") } if erb
    source.gsub(/^([^"'\n]*?)#(?!\{).*$/, '\1')
  end

  def relative(path) = Pathname(path).relative_path_from(ROOT).to_s

  def locale_file(locale)
    YAML.load_file(ROOT.join("config/locales/bali_view.#{locale}.yml")).fetch(locale)
  end

  def flatten(node, prefix = nil)
    return { prefix => node } unless node.is_a?(Hash)

    node.each_with_object({}) do |(key, value), acc|
      acc.merge!(flatten(value, [ prefix, key ].compact.join(".")))
    end
  end
end
