# frozen_string_literal: true

require "test_helper"
require "tempfile"

# Everything in this repo is written in English — identifiers, comments, test names and the
# copy inside Lookbook previews. Spanish stays in the prose written for the team: the
# CHANGELOG, the commit message and the PR body.
#
# The rule is new and the debt is old: 253 files carry 2708 Spanish comment and test-name
# lines. Translating them is six batches of work; keeping the number from growing while that
# happens is this file. So the guard is a RATCHET, not a ban — every offending file is listed
# with its line count in `spanish_in_code_baseline.txt`, and the suite goes red only when a
# file that is not listed acquires Spanish, or a listed one acquires MORE of it.
#
# IT ONLY SHRINKS, AND A STALE ENTRY IS GREEN ON PURPOSE. The six translation batches land in
# an order nobody controls. If a file that has already been translated but is still listed —
# or listed with a count higher than it now has — failed the build, every batch would break
# the ones merged after it, and the list would need a lockstep edit in every branch. So an
# entry that no longer matches reality (translated, shrunk, or deleted outright) costs
# nothing. The price is that shrinking the list is discipline rather than enforcement: the
# batch that translates a file deletes its line, and nothing makes it.
#
# WHAT COUNTS AS SPANISH. An accent or an inverted mark, capitals included, on a line that
# OPENS with a comment marker (`#`, `//`, `/*`, `*`, `<%#`) or that declares a test name
# (`test "..."`, `def test_`, Cypress `describe(`/`it(`). Nothing else. The alphabet lives in
# the `SPANISH` constant below; spelled out, it is
# á é í ó ú ü ñ ¿ ¡ — spanish-ok: the characters this guard is built to find.
# A line of code carrying sample data is not a violation: the sample people are content, not
# language — the gallery shows a Mexican app what it is going to look like, and one of those
# names is the input of the initials test in `avatar_test.rb`.
#
# The opening-marker rule is what keeps that sample data safe, and it was measured rather than
# assumed: Ripper was run over every `.rb` file in the repo and its `on_comment` tokens
# compared against this heuristic. Zero disagreements in the direction that matters — not one
# line this test calls a comment is anything else. In the other direction it missed exactly
# one line, and that line is a trailing comment spelling out the crc32 of a sample name, which
# has to stay. So trailing comments are out of scope: on today's tree, looking for them would
# find one false positive and nothing else.
#
# Spanish written without accents is invisible here. That is the contract, not an oversight —
# an accent is a signal with no false positives, and "word lists" for two languages that share
# most of their Latin roots are not.
class BaliSpanishInCodeTest < ActiveSupport::TestCase
  ROOT = Bali::Engine.root
  BASELINE_PATH = ROOT.join("test/bali/spanish_in_code_baseline.txt")

  SPANISH = /[áéíóúüñÁÉÍÓÚÜÑ¿¡]/
  COMMENT_LINE = %r{\A[ \t]*(?:\#|//|/\*|\*|<%\#)}
  TEST_NAME_LINE = /\A[ \t]*(?:test\s+["']|def\s+test_|(?:describe|it)\s*\(\s*["'`])/

  # The single-line escape hatch, for the line that really is content: a test name that has to
  # quote a sample person, a comment that has to quote a Spanish string it is about. A reason
  # is required, because the next reader's question is always why. The header of this file
  # carries the only one in the repo, on the line that spells out the alphabet — so the
  # mechanism is exercised by its own source and not only by its tests.
  WAIVER = /spanish-ok:\s*\S.{3,}/

  # Only the first lines of a long file are printed. A file already carrying a hundred Spanish
  # lines that grows by one does not need all hundred repeated back.
  LISTED_LINES_SHOWN = 15

  # WHAT IS SWEPT: everything git tracks, plus everything untracked that is not ignored — so a
  # file with Spanish in it is covered the moment it is written, not once it is committed.
  # Asking git rather than listing directories is what closes the holes: `node_modules`, the
  # compiled `spec/dummy/app/assets/builds/*`, and anything else ignored are out for free, and
  # a new top-level source directory is in without anyone remembering to add it.
  #
  # `.github/` and `.claude/` ARE swept, and today they contribute 15 lines across a workflow
  # pair and one hook. They hold shell and YAML that every contributor reads, so there is no
  # reason they should be the corner where Spanish survives.
  #
  # Two things are held out. Binaries, because reading them is meaningless. And PROSE: `.md`
  # anywhere and everything under `docs/`. Markdown has no comment syntax, so the whole file
  # would be either content or nothing; treating a `*` bullet as a comment marker would flag
  # every Spanish bullet in the repo's guides, which this rule is not about.
  UNSCANNED_EXTENSIONS = %w[.md .png .ico .svg .lock .keep .gitkeep].freeze
  UNSCANNED_PREFIXES = %w[docs/].freeze

  # PERMANENT, not debt: these two never join the baseline, because there is no version of
  # them written in English. They are separate from the baseline for exactly that reason — the
  # baseline is a list that is supposed to reach zero, and these would sit in it forever
  # looking like work nobody got to.
  PERMANENTLY_ALLOWED = {
    "config/locales/bali_view.es.yml" =>
      "the Spanish locale. Its comments quote the strings they are about, so they are as " \
      "Spanish as the values underneath them.",
    "app/services/rrule/spanish_humanizer.rb" =>
      "its whole output is Spanish. A comment here names a day, a month or a phrase the " \
      "class emits."
  }.freeze

  class << self
    # { "path/to/file.rb" => [[line_number, "the line"], ...] }, offending lines only.
    def scan
      @scan ||= begin
        @unreadable = []

        scannable_files.each_with_object({}) do |path, found|
          source = read_source(ROOT.join(path))
          next @unreadable << path if source.nil?

          hits = offenses_in(source)
          found[path] = hits if hits.any?
        end
      end
    end

    # A file that cannot be decoded is a file the guard did not look at, and it says so
    # nowhere. The self-test below asserts this stays empty: if a binary slips past
    # UNSCANNED_EXTENSIONS, the answer is to name its extension there, not to let it through.
    def unreadable_files
      scan
      @unreadable
    end

    def scannable_files
      @scannable_files ||= repository_files.reject do |path|
        UNSCANNED_EXTENSIONS.include?(File.extname(path)) ||
          UNSCANNED_PREFIXES.any? { |prefix| path.start_with?(prefix) } ||
          PERMANENTLY_ALLOWED.key?(path)
      end
    end

    def repository_files
      @repository_files ||= begin
        argv = [ "git", "-C", ROOT.to_s, "ls-files", "-z", "--cached", "--others", "--exclude-standard" ]
        out = IO.popen(argv, &:read)
        raise "`git ls-files` failed in #{ROOT}" unless $?.success?

        out.split("\0")
      end
    end

    def read_source(path)
      source = File.read(path, encoding: "UTF-8")
      source.valid_encoding? ? source : nil
    rescue SystemCallError
      nil # a dangling symlink, or a file removed between `ls-files` and here
    end

    def offenses_in(source)
      source.each_line.with_index(1).filter_map do |line, number|
        next unless line.match?(SPANISH)
        next unless line.match?(COMMENT_LINE) || line.match?(TEST_NAME_LINE)
        next if line.match?(WAIVER)

        [ number, line.strip ]
      end
    end

    def offending_lines(path)
      source = read_source(path)
      source ? offenses_in(source) : []
    end

    def baseline
      @baseline ||= baseline_entries.to_h
    end

    # The pairs, in file order and with duplicates intact, so the well-formedness test can see
    # what `to_h` would quietly swallow.
    def baseline_entries
      @baseline_entries ||= parse_baseline(File.read(BASELINE_PATH))
    end

    def parse_baseline(text)
      text.each_line.filter_map do |line|
        line = line.strip
        next if line.empty? || line.start_with?("#")

        path, count = line.split(/\s+/)
        raise "malformed baseline line #{line.inspect}, expected `<path> <lines>`" unless path && count

        [ path, Integer(count) ]
      end
    end

    # THE RATCHET ITSELF, kept as a function of its two inputs so the tests below can drive it
    # with made-up ones. Returns [path, allowed_or_nil, hits] per offending file; `nil` in the
    # middle slot means the file is not listed at all.
    def ratchet_failures(found, baseline)
      found.filter_map do |path, hits|
        allowed = baseline[path]

        if allowed.nil?
          [ path, nil, hits ]
        elsif hits.size > allowed
          [ path, allowed, hits ]
        end
      end
    end

    def failure_report(failures)
      body = failures.map do |path, allowed, hits|
        heading = if allowed.nil?
          "#{path} — not in the baseline, so all #{hits.size} of these are new:"
        else
          "#{path} — the baseline allows #{allowed} lines, the file now has #{hits.size}:"
        end

        shown = hits.first(LISTED_LINES_SHOWN).map { |number, text| "      #{number}: #{text}" }
        shown << "      ... and #{hits.size - LISTED_LINES_SHOWN} more" if hits.size > LISTED_LINES_SHOWN

        ([ "    #{heading}" ] + shown).join("\n")
      end

      <<~MESSAGE
        Spanish reached code the baseline does not cover. This repo is written in English —
        identifiers, comments, test names and preview copy. Spanish stays in the CHANGELOG,
        the commit message and the PR body.

        Two ways out, per line:

          - write it in English; or
          - if the line really is content (a sample person's name, a Spanish string the test
            asserts on), append `spanish-ok: <reason>` to that same line.

        #{body.join("\n")}

        Do not add a file to test/bali/spanish_in_code_baseline.txt, and do not raise a count
        in it. That list is the debt left from before the rule, and it only shrinks.
      MESSAGE
    end
  end

  # The guard is worth nothing if it silently stops looking. A typo in the git invocation, a
  # prefix that swallows the tree, an `ls-files` that returns nothing outside a checkout — all
  # of them read as "no Spanish anywhere" and go green.
  def test_the_scan_actually_reads_the_repository
    assert_operator self.class.repository_files.size, :>, 1_000
    assert_operator self.class.scannable_files.size, :>, 1_000

    assert_includes self.class.scannable_files, "lib/bali/filter_form.rb"
    assert_includes self.class.scannable_files, "cypress/e2e/split-view.cy.js"
    assert_includes self.class.scannable_files, "app/components/bali/table/component.rb"
    assert_includes self.class.scannable_files, ".github/workflows/test.yml"

    assert_not_includes self.class.scannable_files, "CHANGELOG.md"
    assert_not_includes self.class.scannable_files, "docs/guides/components.md"

    assert_empty self.class.unreadable_files,
      "these were swept but could not be decoded, so nobody looked inside them"
  end

  def test_no_file_outside_the_baseline_has_spanish_in_a_comment_or_a_test_name
    failures = self.class.ratchet_failures(self.class.scan, self.class.baseline)

    # `assert`, not `assert_empty`: the latter appends its own `Expected [...] to be empty`
    # after the message, and on a file with 77 offending lines that dump is several screens of
    # inspected arrays under the report that already said everything.
    assert failures.empty?, self.class.failure_report(failures)
  end

  # Both permanent exclusions are spelled the way `git ls-files` spells them, and one of them
  # is load-bearing. Subtracting a path the scan never produces is a no-op that looks like a
  # policy.
  def test_the_permanent_exclusions_are_real_paths_that_would_otherwise_fail
    PERMANENTLY_ALLOWED.each_key do |path|
      assert_includes self.class.repository_files, path
      assert_not_includes self.class.scannable_files, path
      assert_not self.class.baseline.key?(path),
        "#{path} is permanently allowed; it does not belong in the baseline too"
    end

    locale = self.class.offending_lines(ROOT.join("config/locales/bali_view.es.yml"))
    assert_operator locale.size, :>, 0,
      "the Spanish locale no longer trips the scan, so its exclusion proves nothing"
  end

  # A botched merge between two translation batches is the likeliest way this file goes wrong,
  # and a duplicated path silently keeps the LAST count — which may be the larger one.
  def test_the_baseline_file_is_well_formed
    entries = self.class.baseline_entries
    paths = entries.map(&:first)

    assert_operator entries.size, :>, 0
    assert_equal paths.uniq, paths, "duplicate paths in the baseline"
    assert_equal paths.sort, paths, "the baseline is sorted by path, so batches touching " \
                                    "different directories delete from different regions"
    assert entries.all? { |_, count| count.positive? }, "a baseline entry of 0 lines is just noise"
  end

  # --- the ratchet's own behaviour, on inputs that do not depend on the tree ----------------

  def test_it_fails_on_a_file_that_is_not_listed
    found = { "app/components/bali/new/component.rb" => [ [ 3, "# recien escrito" ] ] }

    failures = self.class.ratchet_failures(found, { "lib/bali/other.rb" => 4 })

    assert_equal 1, failures.size
    assert_nil failures.first[1]
    assert_includes self.class.failure_report(failures), "app/components/bali/new/component.rb"
    assert_includes self.class.failure_report(failures), "not in the baseline"
  end

  def test_it_fails_when_a_listed_file_grows
    found = { "lib/bali/filter_form.rb" => Array.new(5) { |i| [ i + 1, "# one more" ] } }

    failures = self.class.ratchet_failures(found, { "lib/bali/filter_form.rb" => 4 })

    assert_equal 1, failures.size
    assert_equal 4, failures.first[1]
    assert_includes self.class.failure_report(failures),
      "the baseline allows 4 lines, the file now has 5"
  end

  # The three shapes of a stale entry, all green. This is the property the six parallel
  # translation batches depend on: whichever order they merge in, none of them can fail
  # because another one got there first.
  def test_a_stale_baseline_entry_does_not_fail
    baseline = {
      "lib/bali/already_translated.rb" => 12, # nothing Spanish left in it
      "lib/bali/partly_translated.rb" => 30,  # it had 30, it has 2
      "lib/bali/deleted.rb" => 7              # the file is gone
    }
    found = { "lib/bali/partly_translated.rb" => [ [ 1, "# one" ], [ 2, "# two" ] ] }

    assert_empty self.class.ratchet_failures(found, baseline)
  end

  def test_it_says_which_line_and_what_to_do_about_it
    found = { "test/bali/widget_test.rb" => [ [ 42, 'test "renderiza el widget" do' ] ] }
    report = self.class.failure_report(self.class.ratchet_failures(found, {}))

    assert_includes report, "42: test"
    assert_includes report, "write it in English"
    assert_includes report, "spanish-ok: <reason>"
    assert_includes report, "only shrinks"
  end

  def test_a_long_file_lists_a_bounded_number_of_lines
    hits = Array.new(40) { |i| [ i + 1, "# one of forty" ] }
    report = self.class.failure_report([ [ "lib/bali/long.rb", nil, hits ] ])

    assert_includes report, "... and 25 more"
    assert_equal LISTED_LINES_SHOWN, report.lines.count { |line| line.match?(/\A\s+\d+: /) }
  end

  # --- the detector, line by line ------------------------------------------------------------

  def test_it_recognises_every_comment_marker
    {
      "ruby" => "# por qué esto va acá",
      "js" => "  // por qué esto va acá",
      "css block" => "/* por qué esto va acá",
      "css continuation" => " * por qué esto va acá",
      "erb" => "<%# por qué esto va acá %>"
    }.each { |kind, line| assert_offending line, kind }
  end

  def test_it_recognises_a_test_name
    assert_offending 'test "renderiza el botón" do', "minitest"
    assert_offending "  def test_renderiza_el_botón", "def test_"
    assert_offending "  it('renderiza el botón', () => {", "cypress it"
    assert_offending '  describe("el botón", () => {', "cypress describe"
  end

  # The whole point of the opening-marker rule: these are the sample data the previews, the
  # avatar test and the humanizer are built on, and the guard has to leave every one alone.
  def test_it_leaves_sample_data_on_a_code_line_alone
    [
      'render_inline(Bali::Avatar::Component.new(name: "Ana García López"))',
      'Bali::Tag::Component.new(text: "Priorización")',
      '<%= render Bali::Card::Component.new(title: "Beto Lara") %>',
      'pair = PALETTE[:red] # crc32("Ana García") % 10',
      "DAY_NAMES = %w[domingo lunes martes miércoles].freeze"
    ].each { |line| refute_offending line, "code line" }
  end

  def test_an_english_comment_is_fine
    refute_offending "# why the obvious thing is wrong here", "english"
  end

  def test_a_waiver_with_a_reason_clears_the_line
    refute_offending 'test "Ana García yields AG" # spanish-ok: the datum under test', "waived"
    assert_offending 'test "Ana García yields AG" do', "the same line without the marker"
  end

  def test_a_waiver_without_a_reason_does_not_clear_the_line
    assert_offending "# está acá por una razón # spanish-ok:", "bare marker"
    assert_offending "# está acá por una razón # spanish-ok: x", "marker with a shrug"
  end

  private

  def assert_offending(line, kind)
    assert_equal [ [ 1, line.strip ] ], scan_string(line),
      "#{kind}: expected this line to be flagged"
  end

  def refute_offending(line, kind)
    assert_empty scan_string(line), "#{kind}: expected this line to be left alone"
  end

  def scan_string(line)
    Tempfile.create([ "spanish", ".rb" ]) do |file|
      file.write("#{line}\n")
      file.flush
      self.class.offending_lines(file.path)
    end
  end
end
