# frozen_string_literal: true

require "test_helper"
require "json"

# `package.json` says a peer is optional. esbuild decides whether that is true.
#
# Measured on a host that installed exactly the three peers every guide called
# required and then wired the documented `registerAll` + `registerCharts`: 22
# `Could not resolve` errors across 12 packages, and the build stopped. Thirteen
# came from ordinary top-level `import` statements — those packages are in every
# bundle whether the host wants them or not, so calling them optional only buys a
# broken build. The other nine came from `await import()`, which esbuild resolves
# at BUNDLE time too, unless the call is guarded with `.catch()` — a hint esbuild
# prints in the error itself.
#
# One number, measured once: the same 22 appears in utils/optional-peer.js, in the
# `//peerDependencies` note in package.json and in docs/guides/installation.md, and
# an earlier pass had it written as both 23 and 21 across those files. The count is
# for the TWO entry points below; `registerAll` on its own is 21 across 11, the one
# fewer being chart.js.
#
# So the contract has two halves, and this test is both:
#
#   a static import of a peer  => that peer is REQUIRED (it is already in the bundle)
#   a dynamic import of a peer => that peer is OPTIONAL, and the call carries .catch()
#
# esbuild accepts a surrounding `try`/`catch` as well — measured: the two `import()`
# calls that already had one raised no error at all. This test is deliberately
# stricter, because a regex cannot tell a `try` that wraps the import from one that
# happens to be nearby, and because one spelling keeps every one of these failures
# reporting through the same `optionalPeer()` message.
#
# The two entry points below are the ones `bin/rails g bali:install` wires into a
# host, so they are the ones whose build has to survive. Entry points a host opts
# into by hand (block-editor, gantt, rich-text-editor) carry their own documented
# dependency sets.
class BaliNpmPeerContractTest < ActiveSupport::TestCase
  ROOT = Bali::Engine.root
  ENTRY_POINTS = [ "app/frontend/bali/index.js", "app/frontend/bali/charts.js" ].freeze

  def test_no_statically_imported_peer_is_declared_optional
    offenders = graph[:static]
      .select { |package, _| optional_peers.include?(package) }
      .transform_values { |sites| sites.sort.join(", ") }

    assert_empty offenders,
                 "these packages are imported with a top-level `import` reachable from " \
                 "#{ENTRY_POINTS.join(' / ')}, so esbuild has to resolve them to build the host " \
                 "at all — `optional: true` in peerDependenciesMeta is a promise package.json " \
                 "cannot keep. Declare them required, or make the import lazy."
  end

  def test_every_dynamic_peer_import_is_guarded_so_a_missing_one_cannot_break_the_build
    assert_empty graph[:unguarded].transform_values { |sites| sites.sort.join(", ") },
                 "esbuild fails the build on an `import()` it cannot resolve, dynamic or not. " \
                 "Add `.catch()` to the call — the same fix esbuild's own error suggests — so a " \
                 "host that skipped an optional peer fails when the component runs, which is " \
                 "what installation.md Step 6 promises."
  end

  # The mirror of the first test, and the half that was quietly wrong: `qr-scanner`
  # was reached only through a guarded `import()`, its controller already raised a
  # "not installed, run yarn add" message, package.json's own prose listed it as
  # optional — and peerDependenciesMeta never said so, so every host installed it.
  def test_a_package_only_ever_imported_lazily_is_declared_optional
    lazy_only = graph[:dynamic].keys - graph[:static].keys
    misdeclared = lazy_only.reject { |package| optional_peers.include?(package) }

    assert_empty misdeclared,
                 "nothing statically imports these, so a host that never renders the component " \
                 "never needs them — say so in peerDependenciesMeta instead of making every " \
                 "app install them"
  end

  # Nothing reachable may be an undeclared package: an import nobody wrote down is
  # one no host can know to install.
  def test_every_reachable_package_is_declared_as_a_peer
    reachable = (graph[:static].keys + graph[:dynamic].keys).uniq
    undeclared = reachable - peer_dependencies.keys - %w[bali-view-components]

    assert_empty undeclared, "imported from the package's own entry points but absent from " \
                             "peerDependencies, so `yarn install` can never produce them"
  end

  # ONE NUMBER, IN FIVE FILES THAT ARE PUBLISHED. The measurement above is quoted
  # in the helper that ships to hosts, in package.json's own note, in the guide and
  # in the CHANGELOG, and an earlier pass had it written as 23 in three of them and
  # 21 in the other two. Whoever re-measures has to change all five, and this is
  # what tells them so.
  MEASUREMENT_FILES = %w[
    app/assets/javascripts/bali/utils/optional-peer.js
    package.json
    docs/guides/installation.md
    CHANGELOG.md
    test/bali/packaging/npm_peer_contract_test.rb
  ].freeze

  # The headline count, and the one for the root entry alone — which the two files
  # that explain the difference are allowed to mention as well.
  BOTH_ENTRY_POINTS = 22
  ROOT_ENTRY_ONLY = 21

  # A number, then `Could not resolve` within a few words of it. Line breaks and the
  # comment markers of five different file formats collapse into single spaces first.
  QUOTED_COUNT = /(\d+)[^\d`]{0,25}`?Could not resolve/

  def test_the_measured_error_count_is_the_same_wherever_it_is_quoted
    quoted = MEASUREMENT_FILES.index_with do |relative|
      ROOT.join(relative).read.gsub(/\s*\n[\s#*"|,>]*/, " ").scan(QUOTED_COUNT).flatten.map(&:to_i)
    end

    assert_empty quoted.select { |_, counts| counts.empty? }.keys,
                 "these files used to quote the measurement and no longer do — either the number " \
                 "moved out of them or the phrasing drifted past this test, which is how the " \
                 "count diverged in the first place"
    assert_empty quoted.reject { |_, counts| counts.first == BOTH_ENTRY_POINTS },
                 "the first count in each file has to be the headline one, #{BOTH_ENTRY_POINTS}"
    assert_empty quoted.transform_values { |counts| counts - [ BOTH_ENTRY_POINTS, ROOT_ENTRY_ONLY ] }
                       .reject { |_, extra| extra.empty? },
                 "a `Could not resolve` count that is neither of the two measured ones"
  end

  private

  def package_json
    @package_json ||= JSON.parse(ROOT.join("package.json").read)
  end

  def peer_dependencies = package_json.fetch("peerDependencies")

  def optional_peers
    @optional_peers ||= package_json.fetch("peerDependenciesMeta")
      .select { |_, meta| meta["optional"] }.keys.to_set
  end

  # { static: { "pkg" => [sites] }, dynamic: {...}, unguarded: {...} }
  def graph
    @graph ||= begin
      found = { static: Hash.new { |h, k| h[k] = [] },
                dynamic: Hash.new { |h, k| h[k] = [] },
                unguarded: Hash.new { |h, k| h[k] = [] } }
      visited = Set.new
      queue = ENTRY_POINTS.map { |entry| ROOT.join(entry) }

      while (path = queue.shift)
        next unless path.exist? && visited.add?(path.to_s)

        source = strip_comments(path.read)
        site = path.relative_path_from(ROOT).to_s

        static_specifiers(source).each do |specifier|
          resolved = resolve(specifier, path)
          resolved ? queue << resolved : found[:static][package_of(specifier)] << site
        end

        dynamic_specifiers(source).each do |specifier, guarded|
          next if resolve(specifier, path)

          found[:dynamic][package_of(specifier)] << site
          found[:unguarded][package_of(specifier)] << site unless guarded
        end
      end

      found
    end
  end

  # JSDoc headers in this package quote whole `import ... from 'bali-view-components'`
  # examples. Left in, they are indistinguishable from code.
  def strip_comments(source)
    source.gsub(%r{/\*.*?\*/}m, "").lines.reject { |line| line.strip.start_with?("//") }.join
  end

  def static_specifiers(source)
    source.scan(/(?:^|\s)(?:import|export)\s[^;\n]*?from\s+["']([^"']+)["']/m).flatten +
      source.scan(/^\s*import\s+["']([^"']+)["']/).flatten
  end

  def dynamic_specifiers(source)
    source.scan(/import\(\s*["']([^"']+)["']\s*\)(\s*\.catch\b)?/m)
          .map { |specifier, guard| [ specifier, !guard.nil? ] }
  end

  EXTENSIONS = [ "", ".js", ".jsx", ".mjs", "/index.js", "/index.jsx" ].freeze

  def resolve(specifier, from)
    return nil unless specifier.start_with?(".")

    EXTENSIONS.lazy.map { |ext| from.dirname.join("#{specifier}#{ext}").cleanpath }
              .find { |candidate| candidate.file? }
  end

  # "date-fns/locale/es" is the date-fns package; "@scope/pkg/sub" is "@scope/pkg".
  def package_of(specifier)
    parts = specifier.split("/")
    specifier.start_with?("@") ? parts.first(2).join("/") : parts.first
  end
end
