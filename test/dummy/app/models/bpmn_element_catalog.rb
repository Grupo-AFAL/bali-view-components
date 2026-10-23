# frozen_string_literal: true

# The Lookbook "Catalog" preview's table: every palette element with what it
# is, when to use it and what the editor does with it (the island's own i18n
# strings, palette_<key>_summary/_when/_editor), the rules that apply to it
# (test/fixtures/bpmn_editor/rule_catalog.json, generated from the rules'
# `appliesTo`) and the palette presets it is in. Nothing here is written twice.
module BpmnElementCatalog
  RULES_PATH = Bali::Engine.root.join("test/fixtures/bpmn_editor/rule_catalog.json")
  GROUPS = {
    "activities" => BpmnSampleFlows::CATALOG["activities"].keys,
    "gateways" => BpmnSampleFlows::CATALOG["gateways"].keys,
    "swimlanes" => %w[lane],
    "connectors" => %w[sequence_flow message_flow association],
    "artifacts" => BpmnSampleFlows::CATALOG["artifacts"].keys,
    "start_events" => BpmnSampleFlows::CATALOG["start_events"].keys,
    "intermediate_events" => BpmnSampleFlows::CATALOG["intermediate_events"].keys,
    "end_events" => BpmnSampleFlows::CATALOG["end_events"].keys
  }.freeze
  PRESETS = Bali::BpmnEditor::Palette::PRESETS

  module_function

  def rules
    @rules ||= JSON.parse(File.read(RULES_PATH))["rules"]
  end

  # [{ group:, label:, items: [{ key:, name:, summary:, when:, editor:, rules: [{ id:, title:, optional: }], presets: }] }]
  def groups(locale)
    texts = Bali::BpmnEditor::Translations.island(locale: locale)
    GROUPS.map do |group, keys|
      { group: group, label: texts["palette_group_#{group}"],
        items: keys.map { |key| item(key, texts) } }
    end
  end

  def item(key, texts)
    applying = rules.select { |rule| rule["appliesTo"].include?(key) }
    { key: key, name: texts["palette_#{key}"],
      summary: texts["palette_#{key}_summary"], when: texts["palette_#{key}_when"], editor: texts["palette_#{key}_editor"],
      rules: applying.map { |rule| { id: rule["id"], title: texts["rule_title_#{rule['id']}"], optional: rule["optional"] } },
      presets: PRESETS.select { |_, keys| keys.include?(key) }.keys }
  end
end
