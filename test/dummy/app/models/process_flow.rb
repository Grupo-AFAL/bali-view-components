# frozen_string_literal: true

# Reference host of Bali::BpmnEditor (#1489): the document lives whole in a
# JSON column; `version` is the optimistic lock the save contract's 409 reads.
# What a real app keeps in its own tables — lanes, activities, assignees —
# would be mapped in and out of the contract here.
class ProcessFlow < ApplicationRecord
  validates :name, presence: true

  # The complete document the island receives, and every 200 returns.
  def to_diagram
    document.deep_symbolize_keys.merge(
      version: version,
      status_label: finalized_at ? "Finalizado v#{version}" : "Borrador v#{version}",
      issues: server_issues
    )
  end

  # Host rules: what only the server can know. The island lists them with its
  # own pending issues; finalizing fails while one is an error.
  def server_issues
    nodes = Array(document["nodes"])
    issues = []
    unless nodes.any? { |n| n["type"] == "user_task" }
      issues << { rule: "APP01", element_id: nil, severity: "warning",
                  message: "El flujo no tiene ninguna tarea de usuario." }
    end
    nodes.select { |n| n["type"] == "sub_process" && n.dig("reference", "id").present? }.each do |node|
      next if ProcessFlowReferences.find(node.dig("reference", "id"))

      issues << { rule: "APP02", element_id: node["id"], severity: "error",
                  message: "El subproceso «#{node['name']}» apunta a un procedimiento que ya no existe." }
    end
    issues
  end

  # Saves a new draft when `expected_version` is the current one; false on a
  # stale version (the caller answers 409).
  def save_draft(diagram, expected_version)
    return false unless expected_version.to_i == version

    update!(document: diagram.except(:version, :status_label, :issues), version: version + 1, finalized_at: nil)
  end
end
