// Rule engine of the editor. Rules registered by the host app join the
// built-in catalog (filled in by the rules phase).
const registry = new Map()

export function registerBpmnRule (rule) {
  if (!rule || !rule.id || typeof rule.check !== 'function') {
    throw new Error('registerBpmnRule needs { id, severity, check(doc, context) }')
  }
  registry.set(String(rule.id), { severity: 'error', ...rule, id: String(rule.id) })
}

export const registeredRules = () => [...registry.values()]
