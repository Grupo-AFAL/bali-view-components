# frozen_string_literal: true

require "test_helper"

# daisyUI 5 renamed its colour tokens (`--p` is `--color-primary`, `--b2` is `--color-base-200`)
# and defines none of the old ones, so a declaration that reads one is invalid at computed-value
# time: it still wins the cascade and computes to `unset`.
class BaliDaisyuiV4TokensCssTest < ActiveSupport::TestCase
  DAISYUI_V4_COLOUR_TOKENS = %w[
    p pc pf s sc sf a ac af n nc nf b1 b2 b3 bc in inc su suc wa wac er erc
  ].freeze
  V4_TOKEN = /var\(\s*--(?:#{DAISYUI_V4_COLOUR_TOKENS.join('|')})\s*[,)]/

  def test_no_stylesheet_reads_a_daisyui_4_colour_token
    sheets = Dir[Bali::Engine.root.join("app/**/*.css").to_s]
    assert_operator(sheets.size, :>, 50) # sanity: the glob found the package's sheets

    offenders = sheets.flat_map do |sheet|
      File.readlines(sheet).each_with_index.filter_map do |line, index|
        "#{sheet.delete_prefix("#{Bali::Engine.root}/")}:#{index + 1}" if line.match?(V4_TOKEN)
      end
    end

    assert_empty(offenders, "daisyUI 4 tokens resolve to nothing under daisyUI 5")
  end
end
