import { test } from 'node:test'
import assert from 'node:assert/strict'
import { evaluate, CATALOG, DEFAULT_ENABLED, isRuleOn, blockPolicy, registerBpmnRule, unregisterBpmnRule, mergeIssues, issuesByElement, ruleList } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../app/components/bali/bpmn_editor/model/rules/afal.js'
// AFAL's guidelines, registered as a host does (afal-package.test.js checks
// that without this import they never run).
import '../../../app/frontend/bali/bpmn-editor-afal-rules.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import { doc, lanes, node, flow } from './helpers.js'

const t = translator({})
const ALL_ON = { enabled: CATALOG.map((r) => r.id) }

// A flow that breaks no rule: every element named and described, splits
// labelled and merged, everything inside its lane.
function clean () {
  return doc({
    lanes: lanes('Accounts payable', 'Treasury'),
    nodes: [
      node('s', 'start_event', 'l1', 100, 90, { name: 'Invoice received', documentation: 'Arrives by email.' }),
      node('t1', 'user_task', 'l1', 250, 90, { name: 'Validate invoice' }),
      node('g', 'exclusive_gateway', 'l1', 420, 90, { name: 'Is it valid?', documentation: 'Checked against the order.' }),
      node('t2', 'task', 'l2', 580, 270, { name: 'Schedule payment' }),
      node('e1', 'end_event', 'l2', 760, 270, { name: 'Invoice paid', documentation: 'Transfer scheduled.' }),
      node('e2', 'end_event', 'l1', 580, 90, { name: 'Invoice rejected', documentation: 'The supplier is notified.' })
    ],
    edges: [flow('f1', 's', 't1'), flow('f2', 't1', 'g'), flow('f3', 'g', 't2', { label: 'Yes' }), flow('f4', 'g', 'e2', { label: 'No' }), flow('f5', 't2', 'e1')]
  })
}
const run = (d, config = ALL_ON) => evaluate(d, config, t, { allowed: config.allowed, page: config.page })
const rulesHit = (d, config) => new Set(run(d, config).map((i) => i.rule))
const by = (d, id) => d.nodes.find((n) => n.id === id)

test('the clean flow passes every rule, optional ones included', () => {
  // R20's default minimum is 2 activities and the clean flow has 2.
  assert.deepEqual(run(clean()), [])
})

// rule id → a mutation of the clean flow that must break it.
const BREAKS = {
  R01: (d) => { d.nodes.push(node('t3', 'task', 'l2', 400, 300, { name: 'Notify supplier' })); d.edges.push(flow('x', 'e2', 't3')); d.edges.push(flow('y', 't3', 't2')); d.nodes.find((n) => n.id === 'e2').type = 'intermediate_throw_event' },
  R02: (d) => { d.edges.push(flow('x', 't1', 'e2')) },
  R03: (d) => { d.edges[3].label = '' },
  R04: (d) => { d.nodes.push(node('e3', 'end_event', 'l1', 580, 150, { name: 'Invoice on hold', documentation: '…' })); d.edges.push(flow('x', 'g', 'e3', { label: 'Maybe' })) },
  // Both paths of the parallel split end in the same event, unmerged.
  R05: (d) => { by(d, 'g').type = 'parallel_gateway'; d.edges[3].target = 'e1' },
  R06: (d) => { by(d, 's').name = 'Start' },
  R07: (d) => { by(d, 'e1').name = 'End' },
  R08: (d) => { messageBefore(d, 'Message') },
  R09: (d) => { by(d, 't2').name = '' },
  R10: (d) => { d.lanes.push({ id: 'l3', name: 'Purchasing', order: 3, size: 180 }) },
  R11: (d) => { d.nodes.push(node('sp', 'sub_process', 'l2', 400, 300, { name: 'Supplier onboarding' })); d.edges.push(flow('x', 'sp', 'e1')); d.edges.push(flow('y', 'e2', 'sp')); by(d, 'e2').type = 'intermediate_throw_event' },
  R12: (d) => { d.nodes = d.nodes.filter((n) => n.type !== 'end_event'); d.edges = d.edges.filter((e) => !['e1', 'e2'].includes(e.target)) },
  R13: (d) => { d.nodes.push(node('t3', 'task', 'l2', 300, 300, { name: 'Archive invoice' })) },
  R14: (d) => { d.nodes.push(node('t3', 'task', 'l2', 300, 300, { name: 'Recheck invoice' })); d.edges.push(flow('x', 't3', 'g')); d.edges.push(flow('y', 's', 't3')) },
  R15: (d) => { d.edges = d.edges.filter((e) => e.id !== 'f4') },
  R16: (d) => { by(d, 't2').name = 'Validate invoice' },
  R17: (d) => { by(d, 't2').name = 'Process' },
  R18: (d) => { by(d, 'e2').x = by(d, 'g').x + 5 },
  R19: (d, config) => { config.options = { max_activities: 1 } },
  R20: (d, config) => { config.options = { min_activities: 5 } },
  R21: (d) => { d.lanes = d.lanes.slice(0, 1); d.nodes.forEach((n) => { n.lane_id = 'l1'; if (n.y > 180) n.y -= 180 }) },
  R22: (d) => { d.lanes[1].name = 'Lane 2' },
  R23: (d) => { by(d, 't2').name = 'New activity' },
  R24: (d) => { d.edges.push(flow('x', 'e1', 't2')) },
  R25: (d) => { d.edges.push(flow('x', 't2', 'gone')) },
  R26: (d) => { by(d, 't2').y = 160 },
  B01: (d) => { by(d, 'g').type = 'event_based_gateway' },
  B02: (d) => { d.edges.push(flow('m', 't1', 't2', { type: 'message_flow' })) },
  B03: (d) => { d.edges.push(flow('a', 't1', 't2', { type: 'association' })) },
  B04: (d) => { d.nodes.push(node('d', 'data_object', 'l2', 300, 300, { name: 'Invoice' })); d.edges.push(flow('x', 't2', 'd')) },
  B05: (d) => { d.nodes.push(node('lk', 'intermediate_throw_event', 'l2', 300, 300, { name: 'To archive', documentation: '…', event_definition: { kind: 'link' } })); d.edges.push(flow('x', 'g', 'lk', { label: 'Later' })) },
  B06: (d) => { by(d, 'e2').event_definition = { kind: 'error' } },
  B07: (d) => { by(d, 'g').type = 'complex_gateway' },
  B08: (d) => { d.nodes.push(node('s2', 'start_event', 'l2', 400, 300, { name: 'Payment requested', documentation: '…' })); d.edges.push(flow('x', 's2', 'e1')) },
  B09: (d) => { d.edges.push(flow('dup', 't2', 'e1')) },
  B10: (d) => { d.nodes.push(node('eg', 'event_based_gateway', 'l2', 400, 300, { name: 'Wait', documentation: '…', instantiate: true })); d.edges.push(flow('x', 'eg', 'e1')); d.edges.push(flow('y', 's', 'eg')) },
  B11: (d) => { by(d, 'g').name = 'Validity check' },
  // A merge of another type than its split: XOR opened, AND closes.
  'COM-19': (d) => { mergeBoth(d, 'parallel_gateway') },
  // An inner split's two paths reach the outer merge directly.
  'COM-20': (d) => {
    mergeBoth(d, 'exclusive_gateway')
    d.nodes.push(node('g2', 'exclusive_gateway', 'l1', 640, 150, { name: 'Supplier known?' }), node('t4', 'task', 'l1', 760, 200, { name: 'Register supplier' }))
    d.edges = d.edges.map((e) => (e.id === 'f4' ? { ...e, target: 'g2' } : e))
    d.edges.push(flow('i1', 'g2', 't3', { label: 'Yes' }), flow('i2', 'g2', 't4', { label: 'No' }), flow('i3', 't4', 'j'))
  },
  'COM-12': (d) => { by(d, 'g').type = 'parallel_gateway' },
  'COM-02': (d) => { binary(d); d.nodes.push(node('e3', 'end_event', 'l1', 580, 150, { name: 'Invoice on hold' })); d.edges.push(flow('x', 'g', 'e3', { label: 'Later' })) },
  'DEC-03': (d) => { binary(d); d.edges[2].label = 'Continue'; d.edges[3].label = 'Stop' },
  // The rework returns straight to the activity it repeats.
  'COM-22': (d) => { rework(d, 't1') },
  'EST-05': (d) => { trap(d) },
  'EST-01': (d) => { trap(d) },
  'EVF-04': (d) => { by(d, 'e2').name = 'Invoice paid' },
  'SUB-05': (d) => {
    d.nodes.push(node('sp', 'sub_process', 'l2', 700, 330, { name: 'Supplier payment', reference: { id: '7', label: 'Supplier payment' } }))
    d.edges = d.edges.map((e) => (e.id === 'f5' ? { ...e, target: 'sp' } : e))
    d.edges.push(flow('x', 'sp', 'e1'))
  },
  'VIS-10': (d, config) => { config.allowed = new Set(['task', 'start_event', 'end_event', 'exclusive_gateway']) },
  // The same flow on a sheet a fifth of a letter page.
  'VIS-02': (d, config) => { config.page = { width: 2, height: 1.7, orientation: 'portrait' } },
  'ACT-02': (d) => { by(d, 't2').name = 'Payment scheduling' },
  'ACT-07': (d) => { by(d, 't2').name = 'Send payment' },
  'ACT-09': (d) => { by(d, 't2').name = 'Follow up payment' },
  'ACT-03': (d) => { by(d, 't2').name = 'Click the pay button' },
  'ACT-10': (d) => { by(d, 't2').name = 'Approve payment' },
  'EVI-03': (d) => { by(d, 'e1').name = 'Notify supplier' },
  'EVI-05': (d) => { by(d, 's').name = 'Monthly closing started' },
  'LAN-08': (d) => { d.lanes[1].name = 'Acct. payable' }
}

// The clean flow with a message event before its last end.
function messageBefore (d, name) {
  d.nodes.push(node('m', 'intermediate_catch_event', 'l2', 680, 270, { name, event_definition: { kind: 'message' } }))
  d.edges = d.edges.map((e) => (e.id === 'f5' ? { ...e, target: 'm' } : e))
  d.edges.push(flow('fm', 'm', 'e1'))
}
// Both answers of the decision continue and meet in a merge of `type`.
function mergeBoth (d, type) {
  d.nodes = d.nodes.filter((n) => n.id !== 'e2')
  d.nodes.push(node('t3', 'task', 'l1', 580, 150, { name: 'Notify supplier' }), node('j', type, 'l2', 700, 270, { name: '' }))
  d.edges = d.edges.filter((e) => e.id !== 'f5').map((e) => (e.id === 'f4' ? { ...e, target: 't3' } : e))
  d.edges.push(flow('a', 't3', 'j'), flow('b', 't2', 'j'), flow('c', 'j', 'e1'))
}
const binary = (d) => { by(d, 'g').marker_visible = false }
// "No" goes to a correction that returns to `target`.
function rework (d, target) {
  d.nodes = d.nodes.filter((n) => n.id !== 'e2')
  d.nodes.push(node('t3', 'task', 'l1', 580, 150, { name: 'Correct invoice' }))
  d.edges = d.edges.map((e) => (e.id === 'f4' ? { ...e, target: 't3' } : e))
  d.edges.push(flow('back', 't3', target))
}
// A third answer leads into a loop nothing leaves.
function trap (d) {
  d.nodes.push(node('t3', 'task', 'l1', 580, 150, { name: 'Hold invoice' }), node('t4', 'task', 'l1', 760, 150, { name: 'Recheck invoice' }))
  d.edges.push(flow('x', 'g', 't3', { label: 'Later' }), flow('y', 't3', 't4'), flow('z', 't4', 't3'))
}

for (const rule of [...CATALOG, ...AFAL_RULES]) {
  test(`${rule.id} fires on the flow that breaks it, and on nothing else of it`, () => {
    assert.ok(BREAKS[rule.id], `no breaking case for ${rule.id}`)
    assert.equal(rulesHit(clean()).has(rule.id), false, 'the clean flow passes')
    const config = { ...ALL_ON }
    const broken = clean()
    BREAKS[rule.id](broken, config)
    const issues = run(broken, config).filter((i) => i.rule === rule.id)
    assert.ok(issues.length > 0, `${rule.id} did not fire`)
    for (const issue of issues) {
      assert.ok(issue.message && !issue.message.includes('%{'), `message of ${rule.id} is filled in: ${issue.message}`)
      assert.ok(['error', 'warning'].includes(issue.severity))
    }
  })
}

test('the issue catalogue and the BPMN-grounded criteria are on by default; the optional rules are off', () => {
  for (const id of ['R01', 'R02', 'R03', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R13', 'R18', 'R21', 'R22', 'R23', 'R24', 'R25', 'R26']) {
    assert.ok(isRuleOn({}, id), `${id} on`)
  }
  // EVI-01, ACT-06 and COM-13 of the criteria matrix turn on R12, R16 and B11.
  for (const id of ['R12', 'R16', 'B11', 'COM-19', 'COM-20', 'COM-12', 'COM-02', 'DEC-03', 'EST-05', 'EST-01', 'VIS-10', 'EVI-03', 'EVI-05']) assert.ok(isRuleOn({}, id), `${id} on`)
  for (const id of ['R04', 'R14', 'R15', 'R17', 'R19', 'R20', 'B07']) assert.equal(isRuleOn({}, id), false, `${id} off`)
  assert.equal(DEFAULT_ENABLED.size, 40)
})

test('every rule of the criteria matrix names its codes, its chapter and its source', () => {
  for (const rule of ruleList({})) {
    assert.ok(rule.section, `${rule.id} has a section`)
    if (/^[A-Z]{3}-\d\d$/.test(rule.id)) {
      assert.ok(rule.criteria.includes(rule.id), `${rule.id} lists its own code`)
      assert.ok(rule.criteria.every((code) => rule.source.includes(code.split('-')[1]) || rule.source.includes(code)), `${rule.id} cites every code in its source: ${rule.source}`)
    }
  }
})

test('the host disables rules, changes severities and rewrites messages', () => {
  const broken = clean()
  by(broken, 's').name = 'Start'
  assert.equal(rulesHit(broken, {}).has('R06'), true)
  assert.equal(rulesHit(broken, { disabled: ['R06'] }).has('R06'), false)
  const [issue] = evaluate(broken, { severities: { R06: 'warning' }, messages: { R06: 'Name the trigger, not «%{name}».' } }, t).filter((i) => i.rule === 'R06')
  assert.equal(issue.severity, 'warning')
  assert.equal(issue.message, 'Name the trigger, not «%{name}».')
})

test('messages come from the translation table', () => {
  const broken = clean()
  messageBefore(broken, 'Message')
  const es = translator({ rule_R08_message: 'Indica qué comunicación espera «%{name}».' })
  assert.equal(evaluate(broken, {}, es).find((i) => i.rule === 'R08').message, 'Indica qué comunicación espera «Message».')
})

test('no element needs a description any more: a decision states its criterion in its name (R08, COM-08)', () => {
  const d = clean()
  for (const n of d.nodes) delete n.documentation
  assert.deepEqual(run(d), [])
})

test('a merging gateway needs neither name nor description', () => {
  const d = clean()
  d.nodes.push(node('m', 'exclusive_gateway', 'l2', 700, 330, { name: '' }), node('t3', 'task', 'l2', 580, 330, { name: 'Pay in cash' }))
  d.edges = d.edges.map((e) => (e.id === 'f5' ? { ...e, target: 'm' } : e))
  d.edges.push(flow('x', 'm', 'e1'), flow('y', 'g', 't3', { label: 'Cash' }), flow('z', 't3', 'm'))
  assert.deepEqual(run(d).filter((i) => i.element_id === 'm'), [])
})

test('an element of an external participant connected by a message flow is not disconnected', () => {
  const d = clean()
  d.lanes[1].kind = 'external'
  d.nodes.push(node('p', 'task', 'l2', 300, 300, { name: 'Send invoice' }))
  d.edges.push(flow('m', 'p', 't1', { type: 'message_flow' }))
  // The AFAL guidelines this file registers judge the activity's wording, not its connections.
  assert.deepEqual(run(d, { disabled: AFAL_RULES.map((r) => r.id) }).filter((i) => i.element_id === 'p'), [])
})

test('registered host rules run with the built-in ones and can be removed', () => {
  registerBpmnRule({ id: 'APP1', severity: 'warning', check: (d) => d.nodes.filter((n) => n.type === 'user_task').map((n) => ({ element_id: n.id, message: 'Assign a form.' })) })
  try {
    const issue = evaluate(clean(), {}, t).find((i) => i.rule === 'APP1')
    assert.deepEqual(issue, { rule: 'APP1', element_id: 't1', severity: 'warning', message: 'Assign a form.', source: 'client' })
    assert.ok(ruleList({}).some((r) => r.id === 'APP1' && r.on))
  } finally {
    unregisterBpmnRule('APP1')
  }
  assert.equal(evaluate(clean(), {}, t).some((i) => i.rule === 'APP1'), false)
})

test('a host rule that throws is skipped', () => {
  registerBpmnRule({ id: 'APP2', check: () => { throw new Error('boom') } })
  const original = console.error
  console.error = () => {}
  try {
    assert.deepEqual(evaluate(clean(), {}, t), [])
  } finally {
    console.error = original
    unregisterBpmnRule('APP2')
  }
})

test('server issues join the client ones without repeating them', () => {
  const client = [{ rule: 'R11', element_id: 'n1', severity: 'error', message: 'x', source: 'client' }]
  const merged = mergeIssues(client, [{ rule: 'R11', element_id: 'n1', message: 'dup' }, { rule: 'APP9', element_id: null, severity: 'warning', message: 'Server says' }])
  assert.deepEqual(merged.map((i) => [i.rule, i.source]), [['R11', 'client'], ['APP9', 'server']])
})

test('a server issue about an element deleted since is dropped', () => {
  const merged = mergeIssues([], [{ rule: 'APP2', element_id: 'gone', severity: 'error' }, { rule: 'APP3', element_id: 't1' }, { rule: 'APP4', element_id: null }], clean())
  assert.deepEqual(merged.map((i) => i.rule), ['APP3', 'APP4'])
})

test('issuesByElement keeps the worst severity per element', () => {
  const map = issuesByElement([{ element_id: 'a', severity: 'warning' }, { element_id: 'a', severity: 'error' }, { element_id: 'b', severity: 'warning' }, { element_id: null, severity: 'error' }])
  assert.deepEqual([...map.entries()], [['a', 'error'], ['b', 'warning']])
})

test('turning a rule off lifts the block that enforces it', () => {
  assert.equal(blockPolicy({}).oneInOneOut, true)
  assert.equal(blockPolicy({ disabled: ['R01', 'R02'] }).oneInOneOut, false)
  assert.equal(blockPolicy({ options: { min_lanes: 3 } }).minLanes, 3)
  assert.equal(blockPolicy({ disabled: ['R21'] }).minLanes, 0)
  assert.equal('noOverlap' in blockPolicy({}), false, 'an overlap is the local arrangement\'s, never a block')
})

// A misspelt id in `rules:` would be ignored without a word.
test('a configured rule id no rule has is warned about once', (context) => {
  const warn = context.mock.method(console, 'warn', () => {})
  const config = { enabled: ['R99', 'R17'], disabled: ['ACT-02'], severities: { 'COM-99': 'warning' }, messages: { R01: 'Custom.' } }
  evaluate(clean(), config, t)
  evaluate(clean(), config, t)
  const said = warn.mock.calls.map((call) => call.arguments[0])
  assert.equal(said.length, 2, said.join(' | '))
  assert.ok(said.some((line) => line.includes('"R99"')))
  assert.ok(said.some((line) => line.includes('"COM-99"')))
})
