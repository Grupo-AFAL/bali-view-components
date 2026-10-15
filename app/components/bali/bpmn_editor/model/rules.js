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

// Rules on by default. Rules listed in `enabled` join them; `disabled` wins.
export const DEFAULT_ENABLED = new Set([
  'R01', 'R02', 'R03', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R13', 'R18', 'R21',
  'R22', 'R23', 'R24', 'R25', 'R26', 'B01', 'B02', 'B03', 'B04', 'B05', 'B06', 'B08', 'B09', 'B10'
])

export function isRuleOn (config, id) {
  const disabled = (config && config.disabled) || []
  const enabled = (config && config.enabled) || []
  if (disabled.includes(id)) return false
  return DEFAULT_ENABLED.has(id) || enabled.includes(id) || registry.has(id)
}

export const ruleOption = (config, key, fallback) => {
  const value = config && config.options && config.options[key]
  return value == null ? fallback : Number(value)
}

// What the editor refuses on the spot, derived from the rules that are on:
// turning a rule off also lifts the block that enforces it.
export function blockPolicy (config) {
  return {
    oneInOneOut: isRuleOn(config, 'R01') || isRuleOn(config, 'R02'),
    noOverlap: isRuleOn(config, 'R18'),
    insideLane: isRuleOn(config, 'R26'),
    minLanes: isRuleOn(config, 'R21') ? ruleOption(config, 'min_lanes', 2) : 0,
    messageFlowParticipants: isRuleOn(config, 'B02'),
    associationArtifact: isRuleOn(config, 'B03'),
    noSequenceOnArtifacts: isRuleOn(config, 'B04')
  }
}
