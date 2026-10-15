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

  module_function

  def search(catalog, query, group = nil)
    catalog.select do |item|
      (query.blank? || item[:label].downcase.include?(query.downcase)) &&
        (group.blank? || item[:group] == group)
    end
  end

  def find(id) = CATALOG.find { |item| item[:id] == id.to_s }
end
