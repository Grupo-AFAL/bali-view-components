// AFAL's guidelines are an optional package (bali-view-components/bpmn-editor/
// afal-rules): until the host imports it they never run, whatever `rules:`
// names; once imported they run, and the host still turns one off. Its own
// file: node --test gives each file a process, so the registry starts empty.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { evaluate, CATALOG, isRuleOn, ruleList } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import { doc, lanes, node, flow } from './helpers.js'

const AFAL = ['ACT-02', 'ACT-03', 'ACT-07', 'ACT-09', 'ACT-10', 'COM-22', 'EVF-04', 'LAN-08', 'SUB-05', 'VIS-02']
const t = translator({})

// "Payment scheduling" is a noun phrase (ACT-02); the two ends share a name (EVF-04).
const flowBreakingAfal = () => doc({
  lanes: lanes('Accounts payable', 'Treasury'),
  nodes: [
    node('s', 'start_event', 'l1', 100, 90, { name: 'Invoice received' }),
    node('t1', 'task', 'l1', 260, 90, { name: 'Payment scheduling' }),
    node('g', 'exclusive_gateway', 'l1', 420, 90, { name: 'Is it valid?' }),
    node('e1', 'end_event', 'l2', 580, 270, { name: 'Invoice closed' }),
    node('e2', 'end_event', 'l1', 580, 90, { name: 'Invoice closed' })
  ],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 'g'), flow('f3', 'g', 'e1', { label: 'Yes' }), flow('f4', 'g', 'e2', { label: 'No' })]
})
const fired = (config) => new Set(evaluate(flowBreakingAfal(), config, t).map((i) => i.rule))

test('the central catalogue carries none of AFAL\'s guidelines, and naming them in `rules:` does not run them', () => {
  const catalogue = new Set(CATALOG.map((rule) => rule.id))
  for (const id of AFAL) assert.equal(catalogue.has(id), false, `${id} is not built in`)
  const hits = fired({ enabled: AFAL })
  for (const id of AFAL) assert.equal(hits.has(id), false, `${id} does not run unregistered`)
})

test('importing the package registers every AFAL guideline: on, listed, and still a host\'s to turn off', async () => {
  const { AFAL_RULE_IDS } = await import('../../../app/frontend/bali/bpmn-editor-afal-rules.js')
  assert.deepEqual([...AFAL_RULE_IDS].sort(), AFAL)
  for (const id of AFAL) assert.ok(isRuleOn({}, id), `${id} on once imported`)
  const listed = new Map(ruleList({}).map((rule) => [rule.id, rule]))
  assert.equal(listed.get('ACT-02').section, 'activities', 'keeps its section for the «Rules» dialog')
  assert.deepEqual(listed.get('VIS-02').criteria, ['VIS-02', 'VIS-08'])
  assert.ok(fired({}).has('ACT-02'))
  assert.ok(fired({}).has('EVF-04'))
  assert.equal(fired({ disabled: ['ACT-02'] }).has('ACT-02'), false)
})

test('the package is a subpath of the npm package', () => {
  const manifest = JSON.parse(fs.readFileSync(new URL('../../../package.json', import.meta.url), 'utf8'))
  assert.equal(manifest.exports['./bpmn-editor/afal-rules'], './app/frontend/bali/bpmn-editor-afal-rules.js')
})
