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

  def test_column_renders_sortable_list
    render_inline(Bali::Kanban::Component.new) do |k|
      k.with_column(title: "Todo", status: "todo") do |col|
        col.with_card { "A" }
      end
    end

    assert_selector("[data-controller='sortable-list']")
  end
end
