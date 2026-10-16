# frozen_string_literal: true

# The entities a sub-process of the reference host can point at, and the
# assignees a lane can take: a fixed, synthetic catalog standing in for the
# host's own data, in English and Spanish
# (test/fixtures/bpmn_editor/references.json, like the samples).
module ProcessFlowReferences
  DATA_PATH = Bali::Engine.root.join("test/fixtures/bpmn_editor/references.json")

  # What the dummy's drawers create live here for as long as the server runs:
  # enough for the round trip the reference implementation shows.
  CREATED = { references: [], assignees: [] } # rubocop:disable Style/MutableConstant

  module_function

  def data
    @data ||= JSON.parse(File.read(DATA_PATH))
  end

  def text(value, locale) = value.is_a?(Hash) ? (value[locale.to_s] || value["en"]) : value
  def group_label(key, locale) = text(data.dig("groups", key), locale)

  # [{ id, label, description, group, area }] in `locale`.
  def references(locale = :es)
    data["references"].map do |item|
      group = group_label(item["area"], locale)
      { id: item["id"], label: text(item["label"], locale), description: group, group: group, area: item["area"] }
    end + CREATED[:references]
  end

  def assignees(locale = :es)
    data["assignees"].map do |item|
      { id: item["id"], label: text(item["label"], locale), group: group_label(item["kind"], locale) }
    end + CREATED[:assignees]
  end

  def create_reference(label, group)
    item = { id: "new-#{SecureRandom.hex(3)}", label: label, description: group, group: group }
    CREATED[:references] << item
    item
  end

  def create_assignee(label, group)
    item = { id: "new-#{SecureRandom.hex(3)}", label: label, group: group }
    CREATED[:assignees] << item
    item
  end

  def search(catalog, query, group = nil)
    catalog.select do |item|
      (query.blank? || item[:label].downcase.include?(query.downcase)) &&
        (group.blank? || item[:group] == group)
    end
  end

  def find(id) = references.find { |item| item[:id] == id.to_s }
end
