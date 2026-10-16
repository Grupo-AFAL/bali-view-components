# frozen_string_literal: true

require "test_helper"

# Lists Ruby validates and the island reads: each one is written on both
# sides, each side naming the other, and this test keeps them equal. It reads
# the JavaScript source, so a constant renamed there fails here.
class BaliBpmnEditorContractTest < ActiveSupport::TestCase
  ROOT = Bali::Engine.root.join("app/components/bali/bpmn_editor")

  def js_list(file, constant)
    source = ROOT.join(file).read
    body = source[/export const #{constant} = \[([^\]]*)\]/m, 1] or flunk "#{constant} not found in #{file}"
    body.scan(/'([^']+)'/).flatten
  end

  def test_edge_types
    assert_equal Bali::BpmnEditor::Data::EDGE_TYPES, js_list("model/catalog.js", "EDGE_TYPES")
  end

  def test_field_types
    assert_equal Bali::BpmnEditor::Component::FIELD_TYPES, js_list("chrome/PropertiesPanel.jsx", "FIELD_TYPES")
  end

  def test_legend_swatches
    assert_equal Bali::BpmnEditor::Component::LEGEND_SWATCHES, js_list("chrome/Legend.jsx", "LEGEND_SWATCHES")
  end

  def test_layouts
    assert_equal Bali::BpmnEditor::Component::LAYOUTS.map(&:to_s), js_list("model/layout.js", "LAYOUTS")
  end

  def test_the_default_page_is_the_islands_letter
    letter = ROOT.join("model/page.js").read[/export const LETTER = \{([^}]*)\}/, 1] or flunk "LETTER not found in page.js"
    js = letter.scan(/(\w+): ('[^']*'|[\d.]+)/).to_h { |key, value| [ key.to_sym, value.start_with?("'") ? value.delete("'") : value.to_f ] }

    assert_equal Bali::BpmnEditor::Component::DEFAULT_PAGE.transform_values { |v| v.is_a?(Numeric) ? v.to_f : v }, js
  end

  # The rule options are the keys the rules read through ctx.option / ruleOption.
  def test_rule_options
    read = Dir[ROOT.join("model/**/*.js")].flat_map do |file|
      File.read(file).scan(/(?:\.option\(|ruleOption\(\w+, )'(\w+)'/).flatten
    end

    assert_equal Bali::BpmnEditor::Component::RULE_OPTIONS.map(&:to_s).sort, read.uniq.sort
  end
end
