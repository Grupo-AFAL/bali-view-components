# frozen_string_literal: true

require "test_helper"

class BaliDataTableToolbarHrefTest < ActiveSupport::TestCase
  # Both halves of the SAME link: the server paints the export href and `export_links_controller.js`
  # re-syncs it from the URL. With the lists apart, moving a param on one side left the other
  # dragging along what the first had just dropped, and nothing failed.
  def test_the_transient_params_list_is_the_same_in_ruby_and_in_javascript
    source = Bali::Engine.root.join("app/components/bali/data_table/export_links_controller.js").read
    literal = source[/const TRANSIENT_PARAMS = \[(.*?)\]/m, 1]
    refute_nil literal, "TRANSIENT_PARAMS literal not found in the controller"

    entries = literal.split(",").map { |entry| entry.strip.delete("'\"") }
    assert_equal Bali::DataTable::ToolbarHref::TRANSIENT_PARAMS, entries
  end
end
