import { test } from 'node:test'
import assert from 'node:assert/strict'
import { withParams, safeUrl } from '../../../app/components/bali/bpmn_editor/model/urls.js'

const BASE = 'https://app.example'

test('the params join the query a URL already has, and its hash stays', () => {
  assert.equal(withParams('/references/new?kind=x#form', { client_node_id: 'n9', editor_id: 'flow_bpmn' }, BASE),
    '/references/new?kind=x&client_node_id=n9&editor_id=flow_bpmn#form')
})

test('a URL on another origin keeps its origin', () => {
  assert.equal(withParams('https://catalog.example/new', { client_node_id: 'n9' }, BASE), 'https://catalog.example/new?client_node_id=n9')
})

test('empty values are left out', () => {
  assert.equal(withParams('/new', { a: '', b: null, c: 'x' }, BASE), '/new?c=x')
})

test('safeUrl keeps paths and http(s), and refuses any other scheme', () => {
  for (const url of ['/processes/7', 'processes/7', '?tab=flow', '#n1', '//catalog.example/7', 'https://catalog.example/7', 'HTTP://catalog.example']) assert.equal(safeUrl(url), url, url)
  for (const url of ['javascript:alert(1)', ' JavaScript:alert(1)', 'java\tscript:alert(1)', 'java\nscript:alert(1)', '\x01javascript:alert(1)', 'data:text/html,<script>alert(1)</script>', 'vbscript:x', '', '  ', null, undefined, 42]) {
    assert.equal(safeUrl(url), null, JSON.stringify(url))
  }
})
