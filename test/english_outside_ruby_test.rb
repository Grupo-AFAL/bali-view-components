# frozen_string_literal: true

require "test_helper"

# The repo is written in English (`.claude/CLAUDE.md`, #1172). `Bali/EnglishOnly` from
# `bali-rubocop` enforces that for Ruby. It parses Ruby, so it cannot see the ERB, JavaScript,
# CSS and shell in the repo — 116 files and 1,299 comments and test names when this sweep
# started (#1174), of which 960 were Cypress `describe`/`it` names. This covers exactly that
# gap, and nothing the cop already owns: `.rb` is absent from GLOBS on purpose.
#
# There is no baseline list. The sweep took these files to zero, so the assertion is zero, and
# a new offender is always a line someone just wrote.
class EnglishOutsideRubyTest < ActiveSupport::TestCase
  ROOT = Pathname.new(File.expand_path("..", __dir__))

  GLOBS = %w[
    app/**/*.erb app/**/*.js app/**/*.css
    cypress/**/*.js cypress/**/*.mjs
    test/dummy/app/**/*.erb test/dummy/app/**/*.js
    .claude/hooks/*.sh
  ].freeze

  # `cypress/screenshots` and `cypress/videos` are gitignored run artifacts, and Cypress names
  # a screenshot's FOLDER after the spec that produced it — so `cypress/**/*.js` matches
  # `cypress/screenshots/split-view.cy.js`, a directory, and reading it raises Errno::EISDIR.
  # Only a local run that failed leaves them, which is why CI never saw it.
  SKIP = %r{/node_modules/|/assets/builds/|/vendor/|\Acypress/(screenshots|videos|downloads)/}

  # Spanish that is content, not code, and stays (#1172): what the gallery shows a Mexican app,
  # and the text a Cypress assertion matches against a page rendered in Spanish.
  ALLOWED_PATHS = [].freeze

  COMMENTS = {
    ".erb" => [ /<%#(.*?)%>/m, /<!--(.*?)-->/m ],
    ".js" => [ %r{//(.*)$}, %r{/\*(.*?)\*/}m ],
    ".mjs" => [ %r{//(.*)$}, %r{/\*(.*?)\*/}m ],
    ".css" => [ %r{/\*(.*?)\*/}m ],
    ".sh" => [ /#(.*)$/ ]
  }.freeze

  TEST_NAME = /\b(?:describe|context|it|specify)\s*\(\s*(['"`])(.+?)\1/m

  ACCENT = /[áéíóúñÁÉÍÓÚÑ¿¡]/

  # Spanish function words with no English homograph. Two or more, at 15% of the words, is
  # Spanish prose — the threshold `Bali/EnglishOnly` uses, so both halves agree on the tilde-less
  # Spanish that an accent search misses (134 such lines surfaced after batch 1 looked clean).
  STOPWORDS = %w[
    el la los las un una unos unas de del al y pero porque que como para por con sin sobre entre
    hasta desde cuando donde quien este esta estos estas ese esa esos esas aquel aquella se le
    les lo nos su sus mi mis tu tus nuestro nuestra es era eran ser estar estan hay tiene tienen
    hace hacen puede pueden debe deben va van ya solo tambien pues aqui alli asi cada todo toda
    todos todas otro otra otros otras mismo misma cual cuales mas menos muy bien mal entonces
    luego antes despues siempre nunca cualquier algun alguna usa usar usando devuelve devuelven
    agrega agregar quita quitar evita evitar deja dejar debajo arriba abajo izquierda derecha
    ancho alto largo corto nuevo nueva sino aunque mientras segun ademas tras bajo ante contra
    hacia durante mediante salvo
  ].to_set.freeze

  WORD = /[A-Za-zÁÉÍÓÚÑáéíóúñ]+/

  def self.spanish?(text)
    return true if text.match?(ACCENT)

    words = text.scan(WORD).map(&:downcase)
    return false if words.size < 4

    hits = words.count { |w| STOPWORDS.include?(w) }
    hits >= 2 && hits.fdiv(words.size) >= 0.15
  end

  def test_no_spanish_in_comments_or_test_names_outside_ruby
    offenses = []

    GLOBS.flat_map { |g| Dir.glob(ROOT.join(g)) }.uniq.sort.each do |path|
      rel = Pathname.new(path).relative_path_from(ROOT).to_s
      next if rel.match?(SKIP) || ALLOWED_PATHS.include?(rel)
      next unless File.file?(path)

      source = File.read(path)
      ext = File.extname(path)

      COMMENTS.fetch(ext, []).each do |pattern|
        source.scan(pattern) do
          body = Regexp.last_match(1)
          next unless self.class.spanish?(body)

          line = source[0...Regexp.last_match.begin(0)].count("\n") + 1
          offenses << "#{rel}:#{line}  #{body.squish.truncate(90)}"
        end
      end

      next unless [ ".js", ".mjs" ].include?(ext)

      source.scan(TEST_NAME) do
        name = Regexp.last_match(2)
        next unless self.class.spanish?(name)

        line = source[0...Regexp.last_match.begin(0)].count("\n") + 1
        offenses << "#{rel}:#{line}  #{name.squish.truncate(90)}"
      end
    end

    assert_empty offenses, <<~MSG
      Spanish outside Ruby, in #{offenses.map { |o| o[/\A[^:]+/] }.uniq.size} file(s):

      #{offenses.join("\n      ")}

      The repo is written in English (.claude/CLAUDE.md). Translate the comment, or delete it if
      it carries no measurement, no constraint invisible from that line, and no reason the obvious
      thing is wrong. Text a Cypress assertion matches against a Spanish page, and sample data
      like `Ana García López`, are content: add the file to ALLOWED_PATHS above and say why.
    MSG
  end
end
