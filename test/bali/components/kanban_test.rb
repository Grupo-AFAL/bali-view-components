# frozen_string_literal: true

require "test_helper"

class BaliKanbanComponentTest < ComponentTestCase
  def test_renders_grid_container
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector("div.grid.grid-cols-1.gap-4")
  end

  def test_renders_columns
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
      k.with_column(title: "Done", status: "done")
    end

    assert_selector("h3", text: "Todo")
    assert_selector("h3", text: "Done")
  end

  def test_grid_cols_match_column_count
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "A", status: "a")
      k.with_column(title: "B", status: "b")
      k.with_column(title: "C", status: "c")
    end

    assert_selector("div.md\\:grid-cols-3")
  end

  def test_grid_cols_cap_at_four
    render_inline(Bali::Kanban::Component.new) do |k|
      5.times { |i| k.with_column(title: "Col #{i}", status: "s#{i}") }
    end

    assert_selector("div.md\\:grid-cols-4")
  end

  def test_renders_cards_in_column
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "Task 1" }
        col.with_card { "Task 2" }
      end
    end

    assert_text("Task 1")
    assert_text("Task 2")
  end

  def test_card_renders_update_url
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card(update_url: "/tasks/1") { "Task" }
      end
    end

    assert_selector("[data-sortable-update-url='/tasks/1']")
  end

  def test_card_without_update_url
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "Static card" }
      end
    end

    assert_no_selector("[data-sortable-update-url]")
  end

  def test_column_auto_counts_cards
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
        col.with_card { "B" }
        col.with_card { "C" }
      end
    end

    assert_selector(".badge-ghost.badge-sm", text: "3")
  end

  def test_column_explicit_count_overrides_auto
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo", count: 10) do |col|
        col.with_card { "A" }
      end
    end

    assert_selector(".badge-ghost.badge-sm", text: "10")
  end

  def test_column_badge_color
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Done", status: "done", color: :success) do |col|
        col.with_card { "A" }
      end
    end

    assert_selector(".badge-success")
  end

  def test_passes_sortable_config_to_columns
    render_inline(Bali::Kanban::Component.new(
      resource_name: "task",
      group_name: "my-board",
      list_param_name: "status"
    )) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
      end
    end

    assert_selector("[data-sortable-list-group-name-value='my-board']")
    assert_selector("[data-sortable-list-list-id-value='todo']")
    assert_selector("[data-sortable-list-resource-name-value='task']")
  end

  def test_column_footer_renders_its_content
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
        col.with_footer { "+ Agregar tarjeta" }
      end
    end

    assert_text("+ Agregar tarjeta")
  end

  def test_column_footer_renders_outside_the_sortable_list
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
        col.with_footer { "+ Agregar tarjeta" }
      end
    end

    assert_no_selector("[data-controller='sortable-list']", text: "+ Agregar tarjeta")
  end

  def test_column_without_footer_renders_no_footer_wrapper
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
      end
    end

    assert_no_selector(".kanban-column-footer")
  end

  def test_column_renders_sortable_list
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
      end
    end

    assert_selector("[data-controller='sortable-list']")
  end

  def test_a11y_column_is_a_list_of_listitems
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
        col.with_card { "B" }
      end
    end

    assert_selector("[role='list']")
    assert_selector("[role='list'] > [role='listitem']", count: 2)
  end

  def test_a11y_column_label_carries_the_count
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
        col.with_card { "B" }
      end
    end

    assert_selector("[role='list'][aria-label='Todo, 2 cards']")
  end

  # The empty column is the case that used to say nothing at all: no count
  # badge, no cards, an unnamed list. It has to announce that it is empty.
  def test_a11y_empty_column_announces_zero
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Backlog", status: "backlog")
    end

    assert_selector("[role='list'][aria-label='Backlog, 0 cards']")
  end

  def test_a11y_column_label_is_singular_for_one_card
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Doing", status: "doing") do |col|
        col.with_card { "A" }
      end
    end

    assert_selector("[role='list'][aria-label='Doing, 1 card']")
  end

  def test_a11y_column_label_is_translated
    I18n.with_locale(:es) do
      render_inline(Bali::Kanban::Component.new) do |k|
        k.with_column(title: "Pendientes", status: "todo")
      end

      assert_selector("[role='list'][aria-label='Pendientes, 0 tarjetas']")
    end
  end

  # A drop moves the DOM and nothing else — no focus change, no text change. The
  # live region is the only channel the outcome can reach a screen reader
  # through, so the board ships one and the announcement template with it.
  def test_a11y_board_renders_a_live_region_for_drops
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector("[role='status'][aria-live='polite'][aria-atomic='true']")
    assert_selector("[data-kanban-target='liveRegion']")
    assert_selector("[data-controller='kanban'][data-action='bali:sortable-list:end->kanban#announce']")
  end

  def test_a11y_board_passes_the_translated_announcement_template
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    template = page.find("[data-controller='kanban']")["data-kanban-announcement-value"]
    assert_equal("%{card} moved to %{column}, position %{position} of %{total}", template)
  end

  # The announcement names the destination column, and JavaScript can only read
  # that off the drop target.
  def test_a11y_list_carries_its_column_title_for_the_announcement
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "In Progress", status: "doing")
    end

    assert_selector("[data-kanban-column-title='In Progress']")
  end

  def test_card_label_overrides_the_announced_name
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card(label: "Design landing page") { "Design landing page - due Mar 25" }
      end
    end

    assert_selector("[data-kanban-card-label='Design landing page']")
  end

  def test_flow_layout_renders_a_scrolling_row_instead_of_a_grid
    render_inline(Bali::Kanban::Component.new(layout: :flow)) do |k|
      5.times { |i| k.with_column(title: "Col #{i}", status: "s#{i}") }
    end

    assert_selector("div.flex.gap-4.overflow-x-auto")
    assert_no_selector("div.grid")
  end

  def test_flow_layout_gives_columns_a_fixed_width
    render_inline(Bali::Kanban::Component.new(layout: :flow)) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector(".kanban-column.w-72.shrink-0")
  end

  def test_grid_layout_leaves_column_width_to_the_grid
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_no_selector(".kanban-column.w-72")
  end

  def test_unknown_layout_raises
    error = assert_raises(ArgumentError) { Bali::Kanban::Component.new(layout: :columns) }
    assert_match(/Unknown Bali::Kanban layout/, error.message)
  end

  def test_viewport_height_caps_the_board
    render_inline(Bali::Kanban::Component.new(height: :viewport)) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    container_class = page.find(".kanban-component > div:not(.sr-only)")[:class]
    assert_includes(container_class, "h-[calc(100vh-var(--bali-kanban-offset,17rem))]")
  end

  def test_height_accepts_a_custom_class
    render_inline(Bali::Kanban::Component.new(height: "h-96")) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector(".kanban-component > div.h-96")
  end

  def test_no_height_by_default
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    container_class = page.find(".kanban-component > div:not(.sr-only)")[:class]
    refute_match(/\bh-/, container_class)
  end

  def test_unknown_height_raises
    error = assert_raises(ArgumentError) { Bali::Kanban::Component.new(height: :full) }
    assert_match(/Unknown Bali::Kanban height/, error.message)
  end

  # The flex-col + min-h-0 pair is what makes a height-capped board scroll per
  # column: without min-h-0 the column refuses to shrink below its content and
  # the page scrolls instead.
  def test_column_is_a_flex_column_that_can_shrink
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector(".kanban-column.flex.flex-col.min-h-0")
  end

  def test_card_list_scrolls_internally_and_fills_the_column
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector(".kanban-column-list.overflow-y-auto.flex-1")
  end

  # The list's min-height moved to kanban/index.css so the empty-column
  # affordance (same property, same layer) can override it. A min-h utility
  # here would win over both and kill the affordance.
  def test_card_list_carries_no_min_height_utility
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    refute_match(/min-h/, page.find(".kanban-column-list")[:class])
  end

  def test_column_forwards_disabled_to_the_sortable_list
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Blocked", status: "blocked", disabled: true)
    end

    assert_selector("[data-sortable-list-disabled-value='true']")
  end

  def test_column_is_not_disabled_by_default
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo")
    end

    assert_selector("[data-sortable-list-disabled-value='false']")
  end
end
