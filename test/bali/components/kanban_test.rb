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
    assert_selector("[data-controller='kanban'][data-action='sortable-list:onEnd->kanban#announce']")
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
end
