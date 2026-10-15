# frozen_string_literal: true

require "test_helper"

class BaliBpmnEditorPaletteTest < ActiveSupport::TestCase
  Palette = Bali::BpmnEditor::Palette
  JS_CATALOG = Rails.root.join("../../app/components/bali/bpmn_editor/model/catalog.js")

  def test_keys_match_the_islands_palette_items_in_order
    js = JS_CATALOG.read[/export const PALETTE_ITEMS = \{(.*?)\n\}/m, 1].scan(/^  ([a-z_]+):/).flatten

    assert_equal js, Palette::KEYS, "Palette::KEYS and PALETTE_ITEMS (model/catalog.js) diverged"
  end

  def test_presets_nest_and_only_name_known_keys
    assert_empty Palette::DESCRIPTIVE - Palette::ANALYTIC
    assert_empty Palette::ANALYTIC - Palette::KEYS
    assert_equal Palette::KEYS, Palette.resolve(:full)[:items].pluck(:key)
  end

  def test_an_array_is_the_exact_list
    items = Palette.resolve(%i[start_event task end_event])[:items]

    assert_equal %w[task start_event end_event], items.pluck(:key)
    assert(items.all? { |item| item[:state] == "enabled" })
  end

  def test_items_add_remove_and_disable_and_notes_mark
    resolved = Palette.resolve(preset: :descriptive,
                               items: { group: false, complex_gateway: true, signal_event: "disabled" },
                               notes: { signal_event: "Pending confirmation" },
                               note_legend: "Dotted: pending", note_label: "pending")
    by_key = resolved[:items].index_by { |item| item[:key] }

    assert_nil by_key["group"]
    assert_equal "enabled", by_key["complex_gateway"][:state]
    assert_equal "disabled", by_key["signal_event"][:state]
    assert_equal "Pending confirmation", by_key["signal_event"][:note]
    assert_equal "Dotted: pending", resolved[:note_legend]
    assert_equal "pending", resolved[:note_label]
  end

  def test_unknown_input_raises
    assert_raises(ArgumentError) { Palette.resolve(:everything) }
    assert_raises(ArgumentError) { Palette.resolve(%i[taks]) }
    assert_raises(ArgumentError) { Palette.resolve(items: { task: "maybe" }) }
    assert_raises(ArgumentError) { Palette.resolve(notes: { teleport: "x" }) }
    assert_raises(ArgumentError) { Palette.resolve(presets: :full) }
  end
end
