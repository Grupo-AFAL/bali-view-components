// Rule engine of the editor: each rule has an id, a default severity, a
// source, and a `check(doc, ctx)` that returns the offending elements. The
// host turns rules on and off, changes their severity and rewrites their
// messages (Bali::BpmnEditor::Component `rules:`), registers its own from JS
// (`registerBpmnRule`) or sends `issues` computed on the server.
//
// The built-in catalogue is catalog/*.js: the issue's R01–R26, the BPMN
// structure rules B01–B11 and the criteria of AFAL's matrix that it grounds
// in BPMN 2.0. AFAL's own guidelines are an optional package
// (bali-view-components/bpmn-editor/afal-rules) that registers its rules.
//
// A rule never blocks saving: issues are what "Finalize" checks. The blocks
// that stop an edit on the spot are blockPolicy() below.
import { isBinaryDecision } from '../catalog.js'
import { layoutLanes } from '../geometry.js'
import { flowStructure } from '../flowStructure.js'
import { LETTER } from '../page.js'
import { plain } from '../wording.js'
import { sequence, words } from './helpers.js'
import { ISSUE_RULES } from './catalog/issues.js'
import { STRUCTURE_RULES } from './catalog/structure.js'
import { CRITERIA_RULES } from './catalog/criteria.js'

export const CATALOG = [...ISSUE_RULES, ...STRUCTURE_RULES, ...CRITERIA_RULES]

const registry = new Map()

export function registerBpmnRule (rule) {
  if (!rule || !rule.id || typeof rule.check !== 'function') {
    throw new Error('registerBpmnRule needs { id, severity, check(doc, context) }')
  }
  registry.set(String(rule.id), { severity: 'error', source: 'app', ...rule, id: String(rule.id) })
}

export const unregisterBpmnRule = (id) => registry.delete(String(id))
export const registeredRules = () => [...registry.values()]

function context (doc, config, t, options = {}) {
  const nodes = doc.nodes || []
  const byId = new Map(nodes.map((n) => [String(n.id), n]))
  const flows = sequence(doc.edges || [])
  const incoming = new Map()
  const outgoing = new Map()
  for (const e of flows) {
    if (!byId.has(String(e.source)) || !byId.has(String(e.target))) continue
    if (!outgoing.has(String(e.source))) outgoing.set(String(e.source), [])
    if (!incoming.has(String(e.target))) incoming.set(String(e.target), [])
    outgoing.get(String(e.source)).push(e)
    incoming.get(String(e.target)).push(e)
  }
  let structure = null
  const list = (key) => (t && t.words ? t.words(key) : [])
  const plainList = (key) => list(key).map(plain).filter(Boolean)
  return {
    doc,
    nodes,
    byId,
    flows,
    layout: layoutLanes(doc),
    inc: (node) => incoming.get(String(node.id)) || [],
    out: (node) => outgoing.get(String(node.id)) || [],
    option: (key, fallback) => ruleOption(config, key, fallback),
    list,
    plainList,
    verbs: () => ({ verbs: plainList('action_verbs'), endings: plainList('infinitive_endings'), exceptions: plainList('not_infinitives') }),
    name: (node) => (node && String(node.name || '').trim()) || (t ? t('unnamed') : ''),
    translate: (key) => (t ? t(key) : key),
    gatewayKind: (node) => (t ? t(isBinaryDecision(node) ? 'palette_binary_decision' : `palette_${node.type}`) : node.type),
    yes: words(t ? t('label_yes') : 'yes'),
    no: words(t ? t('label_no') : 'no'),
    // Palette keys the host allows; null when it restricts nothing.
    allowed: options.allowed || null,
    // The sheet the diagram is meant to print on (Component `page:`).
    page: options.page || LETTER,
    get structure () { return structure || (structure = flowStructure(this)) }
  }
}

// Rules on by default: the issue's standard catalogue, the BPMN structure
// rules and the matrix rules grounded in BPMN 2.0. Off: the issue's optional
// ones (R14, R15, R17, R19), R04 and R20 (domain conventions) and the
// stylistic B07. A registered rule is on until the host disables it.
export const DEFAULT_ENABLED = new Set([
  'R01', 'R02', 'R03', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R12', 'R13', 'R16', 'R18', 'R21',
  'R22', 'R23', 'R24', 'R25', 'R26', 'B01', 'B02', 'B03', 'B04', 'B05', 'B06', 'B08', 'B09', 'B10', 'B11',
  'COM-19', 'COM-20', 'COM-12', 'COM-02', 'DEC-03', 'EST-05', 'EST-01', 'VIS-10', 'EVI-03', 'EVI-05'
])

export function isRuleOn (config, id) {
  const disabled = (config && config.disabled) || []
  const enabled = (config && config.enabled) || []
  if (disabled.includes(id)) return false
  return DEFAULT_ENABLED.has(id) || enabled.includes(id) || registry.has(id)
}

export function ruleOption (config, key, fallback) {
  const value = config && config.options && config.options[key]
  return value == null ? fallback : Number(value)
}

export function severityOf (config, rule) {
  const override = config && config.severities && config.severities[rule.id]
  return override === 'warning' || override === 'error' ? override : rule.severity
}

// Rule ids the configuration names that no rule has — a typo, or an app rule
// whose package was never imported. They would be silently ignored.
export function unknownRuleIds (config) {
  if (!config) return []
  const known = new Set([...CATALOG, ...registeredRules()].map((rule) => rule.id))
  const named = [
    ...(config.enabled || []), ...(config.disabled || []),
    ...Object.keys(config.severities || {}), ...Object.keys(config.messages || {})
  ].map(String)
  return [...new Set(named)].filter((id) => !known.has(id))
}

const warned = new Set()
function warnUnknown (config) {
  for (const id of unknownRuleIds(config)) {
    if (warned.has(id) || typeof console === 'undefined') continue
    warned.add(id)
    console.warn(`bpmn rules: "${id}" is configured but no rule has that id`)
  }
}

// Every rule the editor knows, built-in and registered, with its state.
export function ruleList (config) {
  return [...CATALOG, ...registeredRules()].map((rule) => ({
    id: rule.id,
    source: rule.source,
    title: rule.title,
    section: rule.section || 'app',
    criteria: rule.criteria || [],
    on: isRuleOn(config, rule.id),
    severity: severityOf(config, rule)
  }))
}

// Issues of a document: [{ rule, element_id, severity, message, source }].
// `options.allowed`: the palette keys the host enables (VIS-10); `options.page`:
// the sheet it prints on.
export function evaluate (doc, config = {}, t = null, options = {}) {
  warnUnknown(config)
  const ctx = context(doc, config, t, options)
  const messages = (config && config.messages) || {}
  const found = []
  for (const rule of [...CATALOG, ...registeredRules()]) {
    if (!isRuleOn(config, rule.id)) continue
    const severity = severityOf(config, rule)
    let hits = []
    try {
      hits = rule.check(doc, ctx) || []
    } catch (error) {
      // A host rule that throws must not take the editor down with it.
      if (typeof console !== 'undefined') console.error(`bpmn rule ${rule.id} failed`, error)
      continue
    }
    for (const hit of hits) {
      const vars = hit.vars || {}
      const custom = messages[rule.id]
      const key = hit.key ? `rule_${rule.id}_${hit.key}` : `rule_${rule.id}`
      let message = hit.message
      if (!message && custom) message = interpolate(custom, vars)
      if (!message && t) message = t(key, vars)
      found.push({
        rule: rule.id,
        element_id: hit.element_id == null ? null : String(hit.element_id),
        severity: hit.severity || severity,
        message: message || rule.id,
        source: 'client'
      })
    }
  }
  return found
}

function interpolate (template, vars) {
  return Object.entries(vars).reduce((text, [name, value]) => text.replaceAll(`%{${name}}`, () => String(value)), String(template))
}

// Issues computed by the server (the document's `issues`) next to the
// client's. Server rules the client also knows are not repeated, and an issue
// about an element deleted since the last save is gone with it.
export function mergeIssues (client, server, doc = null) {
  const seen = new Set(client.map((i) => `${i.rule}:${i.element_id}`))
  const exists = doc
    ? new Set([...(doc.nodes || []), ...(doc.edges || []), ...(doc.lanes || [])].map((e) => String(e.id)))
    : null
  const fromServer = (server || []).filter((i) => !seen.has(`${i.rule}:${i.element_id ?? null}`))
    .filter((i) => !exists || i.element_id == null || exists.has(String(i.element_id))).map((i) => ({
      rule: String(i.rule), element_id: i.element_id == null ? null : String(i.element_id), severity: i.severity === 'warning' ? 'warning' : 'error', message: i.message || String(i.rule), source: 'server'
    }))
  return [...client, ...fromServer]
}

// Element id → the worst severity on it, for the canvas markers.
export function issuesByElement (issues) {
  const map = new Map()
  for (const issue of issues) {
    if (issue.element_id == null) continue
    if (map.get(issue.element_id) !== 'error') map.set(issue.element_id, issue.severity)
  }
  return map
}

export const hasErrors = (issues) => issues.some((i) => i.severity === 'error')

// What the editor refuses on the spot, derived from the rules that are on:
// turning a rule off also lifts the block that enforces it.
export function blockPolicy (config) {
  return {
    oneInOneOut: isRuleOn(config, 'R01') || isRuleOn(config, 'R02'),
    insideLane: isRuleOn(config, 'R26'),
    minLanes: isRuleOn(config, 'R21') ? ruleOption(config, 'min_lanes', 2) : 0,
    messageFlowParticipants: isRuleOn(config, 'B02'),
    associationArtifact: isRuleOn(config, 'B03'),
    noSequenceOnArtifacts: isRuleOn(config, 'B04')
  }
}
