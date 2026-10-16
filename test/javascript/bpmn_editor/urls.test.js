import { test } from 'node:test'
import assert from 'node:assert/strict'
import { withParams } from '../../../app/components/bali/bpmn_editor/model/urls.js'

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
