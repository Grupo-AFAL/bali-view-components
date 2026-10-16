# frozen_string_literal: true

require "test_helper"

# The rules gallery preview (Bali::BpmnEditor::Preview#rules_gallery): every
# rule's failing and passing example renders, with the issues panel set to
# open and the rule switched on; the optional package's rules load their own
# island bundle. The examples are test/fixtures/bpmn_editor/rule_examples.json,
# which rules.test.js keeps equal to the editor's rule catalogue.
class BpmnEditorRulesGalleryTest < ActionDispatch::IntegrationTest
  def island
    css_select("[data-controller='bpmn-editor']").first
  end

  BpmnRuleExamples.rule_ids.each do |rule|
    BpmnRuleExamples::EXAMPLES.each do |example|
      define_method("test_#{rule.tr('-', '_')}_#{example}_example_renders") do
        get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: rule, example: example, optional_rules: true }

        assert_response :ok
        assert_equal "true", island["data-bpmn-editor-open-issues-value"]
        assert_equal "true", island["data-bpmn-editor-editable-value"]
        assert_equal [ rule ], JSON.parse(island["data-bpmn-editor-rules-value"])["enabled"]
        expected = BpmnRuleExamples.example(rule, example)[:document]["nodes"].pluck("id")
        assert_equal expected, JSON.parse(island["data-bpmn-editor-data-value"])["nodes"].pluck("id")
      end
    end
  end

  # The failing example raises its rule; a rule it cannot help breaking too
  # is said on the page, with the reason the example file gives.
  def test_a_failing_example_names_the_rule_it_cannot_help_breaking_too
    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: "COM-22", example: "failing", locale: "en" }
    assert_select "[data-testid='bpmn-rules-gallery-also']", text: /R01:.*second way in/

    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: "COM-22", example: "passing", locale: "en" }
    assert_select "[data-testid='bpmn-rules-gallery-also']", count: 0

    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: "R17", example: "failing", locale: "en" }
    assert_select "[data-testid='bpmn-rules-gallery-also']", count: 0, message: "ACT-02 is the optional package's, not loaded"
  end

  def test_the_examples_come_in_the_language_of_the_page
    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: "R16", example: "failing", locale: "es" }
    names = JSON.parse(island["data-bpmn-editor-data-value"])["nodes"].pluck("name")
    assert_includes names, "Programar el pago"

    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: "R16", example: "failing", locale: "en" }
    assert_includes JSON.parse(island["data-bpmn-editor-data-value"])["nodes"].pluck("name"), "Schedule payment"
  end

  def test_the_rule_select_offers_every_example
    preview = Bali::BpmnEditor::Preview.new
    assert_equal BpmnRuleExamples.rule_ids, preview.send(:gallery_rules)
    assert_operator BpmnRuleExamples.rule_ids.size, :>, 50
  end

  def test_an_optional_rule_needs_the_optional_package_and_says_so
    rule = BpmnRuleExamples.optional_rule_ids.first

    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: rule, example: "failing" }
    assert_select "[data-testid='bpmn-rules-gallery-optional']"
    assert_select "meta[name='bali-bpmn-editor-js'][content*='with-rules']", count: 0
    assert_empty JSON.parse(island["data-bpmn-editor-rules-value"])["enabled"]

    get "/lookbook/preview/bali/bpmn_editor/rules_gallery", params: { rule: rule, example: "failing", optional_rules: true }
    assert_select "[data-testid='bpmn-rules-gallery-optional']", count: 0
    assert_select "meta[name='bali-bpmn-editor-js'][content*='bpmn-editor-island-with-rules']"
  end
end
