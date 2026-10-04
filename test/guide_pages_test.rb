# frozen_string_literal: true

require "test_helper"

# A Lookbook guide is ERB before it is Markdown, so a `<%#` inside a code sample is a comment of the
# page itself: ERB strips it and the rendered sample loses the line without a trace, where a stray
# `<%=` at least prints or raises. The component-patterns guide had lost seven that way (#1303).
class GuidePagesTest < ActiveSupport::TestCase
  PAGES = Rails.root.join("app/views/lookbook/pages")

  def test_no_code_sample_in_a_guide_holds_an_unescaped_erb_comment
    offenders = Dir[PAGES.join("**/*.md.erb")].sort.flat_map do |path|
      in_sample = false

      File.readlines(path).each_with_index.filter_map do |line, index|
        in_sample = !in_sample if line.start_with?("```")
        "  #{Pathname(path).relative_path_from(PAGES)}:#{index + 1}" if in_sample && line.include?("<%#")
      end
    end

    assert_empty offenders, <<~MSG
      These code samples hold a `<%#` that ERB removes before the page renders. Write it `<%%#`:

      #{offenders.join("\n")}
    MSG
  end
end
