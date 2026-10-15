# frozen_string_literal: true

# The entities a sub-process of the reference host can point at: a fixed,
# synthetic catalog standing in for the host's own procedures.
module ProcessFlowReferences
  CATALOG = [
    { id: "101", label: "Alta de proveedor", description: "Compras", group: "Compras" },
    { id: "102", label: "Evaluación de proveedores", description: "Compras", group: "Compras" },
    { id: "201", label: "Conciliación bancaria", description: "Tesorería", group: "Tesorería" },
    { id: "202", label: "Programación de pagos", description: "Tesorería", group: "Tesorería" },
    { id: "301", label: "Cierre contable mensual", description: "Contabilidad", group: "Contabilidad" }
  ].freeze

  ASSIGNEES = [
    { id: "area:1", label: "Cuentas por pagar", group: "Área" },
    { id: "area:2", label: "Tesorería", group: "Área" },
    { id: "role:1", label: "Analista de compras", group: "Rol" },
    { id: "role:2", label: "Gerente de finanzas", group: "Rol" },
    { id: "external:1", label: "Proveedor", group: "Externo" }
  ].freeze

  # What the dummy's drawers create live here for as long as the server runs:
  # enough for the round trip the reference implementation shows.
  CREATED = { references: [], assignees: [] } # rubocop:disable Style/MutableConstant

  module_function

  def references = CATALOG + CREATED[:references]
  def assignees = ASSIGNEES + CREATED[:assignees]

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
