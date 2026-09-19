# frozen_string_literal: true

require "test_helper"

# Nothing else exercises the cell previews: the component tests render classes,
# not previews, and Cypress does not visit StatCard. A preview that 500s — a
# misspelled sibling constant, a moved partial — leaves the gallery broken with
# Minitest green, which is what `.claude/CLAUDE.md` warns about preview autoloading.
class StatCardPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "/lookbook/preview/bali/stat_card/cells_in_card" => 6,
    "/lookbook/preview/bali/stat_card/surfaces_compared" => 1,
    "/lookbook/preview/bali/stat_card/emphasised_cell" => 1
  }.freeze

  def test_each_cell_preview_renders_its_cells
    PREVIEWS.each do |path, cells|
      get path
      assert_response :ok, "#{path} did not render"
      assert_select ".rounded-box.border.p-4", { count: cells },
                    "#{path} rendered a number of cells other than #{cells}"
    end
  end

  def test_the_grid_of_cells_emits_exactly_one_card
    get "/lookbook/preview/bali/stat_card/cells_in_card"

    assert_response :ok
    assert_select ".card", { count: 1 }, "the grid emitted nested cards"
    assert_select ".stat", false, "the cell emitted daisyUI's .stat markup"
  end

  # The parameter the guide's `value_class:` measurement rests on: without it the
  # measurement stops being reproducible from the gallery.
  def test_the_emphasised_cell_preview_takes_a_value_class
    get "/lookbook/preview/bali/stat_card/emphasised_cell", params: { value_class: "text-xl" }

    assert_response :ok
    assert_select "p.text-3xl.font-bold.text-xl", { count: 1 }
  end
end
