# frozen_string_literal: true

require "test_helper"

class BaliBpmnEditorTranslationsTest < ActiveSupport::TestCase
  JS_TABLE = Rails.root.join("../../app/components/bali/bpmn_editor/i18n.js")

  def js_keys
    JS_TABLE.read[/DEFAULT_I18N = \{(.*?)\n\}/m, 1].scan(/^  ([a-z0-9_A-Z]+):/).flatten
  end

  def test_both_locales_serve_exactly_the_js_keys
    %i[en es].each do |locale|
      table = Bali::BpmnEditor::Translations.island(locale: locale)

      assert_equal js_keys.sort, table.keys.sort, "locale #{locale} and DEFAULT_I18N (i18n.js) diverged"
      table.each { |key, value| assert value.present?, "#{locale}/#{key} is empty" }
    end
  end

  def test_placeholders_reach_the_client_uninterpolated
    table = Bali::BpmnEditor::Translations.island(locale: :es)

    assert_includes table["pending_other"], "%{count}"
    assert_includes table["rule_R01"], "%{name}"
  end

  # Every placeholder of the English string exists in the Spanish one, or the
  # island would print a literal "%{name}".
  def test_spanish_keeps_the_english_placeholders
    en = Bali::BpmnEditor::Translations.island(locale: :en)
    es = Bali::BpmnEditor::Translations.island(locale: :es)

    en.each do |key, value|
      assert_equal value.scan(/%\{\w+\}/).sort, es[key].scan(/%\{\w+\}/).sort, "placeholders of #{key}"
    end
  end
end
