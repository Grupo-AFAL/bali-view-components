import { test } from 'node:test'
import assert from 'node:assert/strict'
import { evaluate, CATALOG, DEFAULT_ENABLED, isRuleOn, blockPolicy, registerBpmnRule, unregisterBpmnRule, mergeIssues, issuesByElement, ruleList } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../app/components/bali/bpmn_editor/model/rules/afal.js'
// AFAL's guidelines, registered as a host does (afal-package.test.js checks
// that without this import they never run).
import '../../../app/frontend/bali/bpmn-editor-afal-rules.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import { node, flow } from './helpers.js'
import { RULE_EXAMPLES, exampleDocument, exampleOptions, TRANSLATORS } from './support/ruleExamples.js'

const t = translator({})
const ALL_ON = { enabled: CATALOG.map((r) => r.id) }

// The clean flow and, per rule, a flow that breaks it: test/fixtures/
// bpmn_editor/rule_examples.json, shared with the rules gallery preview.
const clean = () => exampleDocument(RULE_EXAMPLES.documents.clean)
const run = (d, config = ALL_ON) => evaluate(d, config, t, { allowed: config.allowed, page: config.page })
const rulesHit = (d, config) => new Set(run(d, config).map((i) => i.rule))
const by = (d, id) => d.nodes.find((n) => n.id === id)

test('the clean flow passes every rule, optional ones included', () => {
  // R20's default minimum is 2 activities and the clean flow has 2.
  assert.deepEqual(run(clean()), [])
})

// The clean flow with a message event before its last end.
function messageBefore (d, name) {
  d.nodes.push(node('m', 'intermediate_catch_event', 'l2', 680, 270, { name, event_definition: { kind: 'message' } }))
  d.edges = d.edges.map((e) => (e.id === 'f5' ? { ...e, target: 'm' } : e))
  d.edges.push(flow('fm', 'm', 'e1'))
}

for (const rule of [...CATALOG, ...AFAL_RULES]) {
  test(`${rule.id} fires on the flow that breaks it, and on nothing else of it`, () => {
    const example = RULE_EXAMPLES.rules[rule.id]
    assert.ok(example, `no breaking case for ${rule.id}`)
    assert.equal(rulesHit(exampleDocument(example.passing)).has(rule.id), false, 'the clean flow passes')
    const config = { ...ALL_ON, ...exampleOptions(example) }
    const broken = exampleDocument(example.failing)
    const issues = run(broken, config).filter((i) => i.rule === rule.id)
    assert.ok(issues.length > 0, `${rule.id} did not fire`)
    for (const issue of issues) {
      assert.ok(issue.message && !issue.message.includes('%{'), `message of ${rule.id} is filled in: ${issue.message}`)
      assert.ok(['error', 'warning'].includes(issue.severity))
    }
  })
}

// The rules gallery preview shows each example with only its own rule switched
// on (`rules: { enabled: [id], options }`), the palette it allows and its sheet:
// with that much, the failing example raises the rule and the passing one not.
for (const [id, example] of Object.entries(RULE_EXAMPLES.rules)) {
  test(`the gallery's ${id} examples: the failing one raises it with only it switched on, the passing one does not`, () => {
    const gallery = (which) => {
      const { allowed, page, options } = exampleOptions(example, which)
      return evaluate(exampleDocument(example[which]), { enabled: [id], options }, t, { allowed, page }).filter((i) => i.rule === id)
    }
    assert.ok(gallery('failing').length > 0, `${id} did not fire`)
    assert.deepEqual(gallery('passing'), [])
  })
}

// Isolated examples: as the gallery shows them — the central rules on as
// they ship, the optional package registered, the example's rule switched on
// with its options — the failing example raises its rule and nothing else
// (bar what its entry declares in `also`), the passing one raises nothing. In
// both languages: each text is { en, es }, checked with that locale's lists.
for (const [id, example] of Object.entries(RULE_EXAMPLES.rules)) {
  for (const [locale, translate] of Object.entries(TRANSLATORS)) {
    test(`the gallery's ${id} examples in ${locale}: the failing one raises only ${id}, the passing one nothing`, () => {
      const raised = (which) => {
        const { allowed, page, options } = exampleOptions(example, which)
        const issues = evaluate(exampleDocument(example[which], locale), { enabled: [id], options }, translate, { allowed, page })
        return [...new Set(issues.map((i) => i.rule))].sort()
      }
      const also = Array.isArray(example.also) ? example.also : ((example.also || {})[locale] || [])
      assert.deepEqual(raised('failing'), [...new Set([id, ...also])].sort())
      assert.deepEqual(raised('passing'), [])
    })
  }
}

test('an example that also breaks another rule says why', () => {
  for (const [id, example] of Object.entries(RULE_EXAMPLES.rules)) {
    if (example.also) assert.ok(example.why, `${id} lists also: without why`)
  }
})

// The rules gallery preview reads the same file: it offers exactly the rules
// there are, and says which come from the optional package.
test('every example in rule_examples.json belongs to a rule, and the optional package is marked as such', () => {
  const ids = [...CATALOG, ...AFAL_RULES].map((rule) => rule.id).sort()
  assert.deepEqual(Object.keys(RULE_EXAMPLES.rules).sort(), ids)
  const optional = Object.entries(RULE_EXAMPLES.rules).filter(([, example]) => example.package === 'optional').map(([id]) => id).sort()
  assert.deepEqual(optional, AFAL_RULES.map((rule) => rule.id).sort())
})

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
