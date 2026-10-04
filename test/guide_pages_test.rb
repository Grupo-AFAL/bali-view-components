# frozen_string_literal: true

require "test_helper"

# A Lookbook guide is ERB before it is Markdown, so a `<%#` meant for a code sample — fenced,
# indented or inline — is a comment of the page itself: ERB strips it and the reader never sees
# the line, where a stray `<%=` at least prints or raises. No guide needs a comment of its own,
# so none is allowed anywhere.
class GuidePagesTest < ActiveSupport::TestCase
  PAGES = Rails.root.join("app/views/lookbook/pages")

  def test_no_guide_holds_an_unescaped_erb_comment
    offenders = Dir[PAGES.join("**/*.md.erb")].sort.flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "  #{Pathname(path).relative_path_from(PAGES)}:#{index + 1}" if line.include?("<%#")
      end
    end

    assert_empty offenders, <<~MSG
      These guides hold a `<%#` that ERB removes before the page renders. Write it `<%%#`:

      #{offenders.join("\n")}
    MSG
  end
end
