// Reference flows for the layout quality checks. `invoice` mirrors the
// dummy's BpmnSampleFlows.invoice (positioned by hand); the others carry no
// coordinates and are laid out by the code under test.

export function invoice () {
  return {
    version: 1,
    orientation: 'horizontal',
    pool: { x: 0, y: 0 },
    lanes: [
      { id: 'l1', name: 'Supplier', kind: 'external', order: 1, size: 160 },
      { id: 'l2', name: 'Accounts payable', kind: 'internal', order: 2, size: 180 },
      { id: 'l3', name: 'Treasury', kind: 'internal', order: 3, size: 160 }
    ],
    nodes: [
      { id: 'p1', type: 'task', lane_id: 'l1', name: 'Issue invoice', x: 70, y: 48 },
      { id: 's1', type: 'start_event', lane_id: 'l2', name: 'Invoice received', event_definition: { kind: 'message' }, x: 127, y: 232 },
      { id: 't1', type: 'user_task', lane_id: 'l2', name: 'Validate invoice', x: 220, y: 218 },
      { id: 'g1', type: 'exclusive_gateway', lane_id: 'l2', name: 'Is the invoice valid?', x: 430, y: 225 },
      { id: 'e2', type: 'end_event', lane_id: 'l2', name: 'Invoice rejected', x: 600, y: 232 },
      { id: 't3', type: 'task', lane_id: 'l3', name: 'Record payment', x: 530, y: 388 },
      { id: 't4', type: 'service_task', lane_id: 'l3', name: 'Schedule transfer', x: 740, y: 388 },
      { id: 'e1', type: 'end_event', lane_id: 'l3', name: 'Payment made', x: 960, y: 402 },
      { id: 'a1', type: 'text_annotation', name: 'Check tax id, amounts and purchase order', x: 300, y: 30 }
    ],
    edges: [
      { id: 'm1', type: 'message_flow', source: 'p1', target: 's1' },
      { id: 'f1', source: 's1', target: 't1' },
      { id: 'f2', source: 't1', target: 'g1' },
      { id: 'f3', source: 'g1', target: 't3', label: 'Yes' },
      { id: 'f4', source: 'g1', target: 'e2', label: 'No' },
      { id: 'f5', source: 't3', target: 't4' },
      { id: 'f6', source: 't4', target: 'e1' },
      { id: 'as1', type: 'association', source: 'a1', target: 't1' }
    ]
  }
}

const strip = (doc) => ({ ...doc, nodes: doc.nodes.map(({ x, y, ...n }) => n) })

export function rework () {
  return strip({
    version: 1,
    lanes: [{ id: 'a', name: 'Requester', order: 1 }, { id: 'b', name: 'Reviewer', order: 2 }],
    nodes: [
      { id: 's', type: 'start_event', lane_id: 'a', name: 'Request needed' },
      { id: 't1', type: 'task', lane_id: 'a', name: 'Fill in request' },
      { id: 't2', type: 'task', lane_id: 'b', name: 'Review request' },
      { id: 'g', type: 'exclusive_gateway', lane_id: 'b', name: 'Complete?' },
      { id: 't3', type: 'task', lane_id: 'a', name: 'Fix request' },
      { id: 't4', type: 'task', lane_id: 'b', name: 'Approve request' },
      { id: 'e', type: 'end_event', lane_id: 'b', name: 'Request approved' }
    ],
    edges: [
      { id: 'f1', source: 's', target: 't1' }, { id: 'f2', source: 't1', target: 't2' },
      { id: 'f3', source: 't2', target: 'g' }, { id: 'f4', source: 'g', target: 't4', label: 'Yes' },
      { id: 'f5', source: 'g', target: 't3', label: 'No' }, { id: 'f6', source: 't3', target: 't2' },
      { id: 'f7', source: 't4', target: 'e' }
    ]
  })
}

export function parallel () {
  return strip({
    version: 1,
    lanes: [{ id: 'a', name: 'Purchasing', order: 1 }, { id: 'b', name: 'Warehouse', order: 2 }],
    nodes: [
      { id: 's', type: 'start_event', lane_id: 'a', name: 'Order placed' },
      { id: 'split', type: 'parallel_gateway', lane_id: 'a', name: '' },
      { id: 'b1', type: 'task', lane_id: 'a', name: 'Confirm supplier' },
      { id: 'b2', type: 'task', lane_id: 'a', name: 'Book carrier' },
      { id: 'b3', type: 'task', lane_id: 'b', name: 'Reserve space' },
      { id: 'join', type: 'parallel_gateway', lane_id: 'a', name: '' },
      { id: 't', type: 'task', lane_id: 'a', name: 'Close order' },
      { id: 'e', type: 'end_event', lane_id: 'a', name: 'Order ready' }
    ],
    edges: [
      { id: 'f1', source: 's', target: 'split' }, { id: 'f2', source: 'split', target: 'b1' },
      { id: 'f3', source: 'split', target: 'b2' }, { id: 'f4', source: 'split', target: 'b3' },
      { id: 'f5', source: 'b1', target: 'join' }, { id: 'f6', source: 'b2', target: 'join' },
      { id: 'f7', source: 'b3', target: 'join' }, { id: 'f8', source: 'join', target: 't' },
      { id: 'f9', source: 't', target: 'e' }
    ]
  })
}

// Mirrors BpmnSampleFlows.large: runs of steps per lane, a decision every
// six steps.
export function large (activities = 60, every = 6) {
  const lanes = ['Requester', 'Purchasing', 'Warehouse', 'Finance'].map((name, i) => ({ id: `l${i + 1}`, name, order: i + 1 }))
  const nodes = [{ id: 'start', type: 'start_event', lane_id: 'l1', name: 'Need detected' }]
  const edges = []
  let previous = 'start'
  for (let step = 1; step <= activities; step++) {
    const lane = `l${(Math.floor((step - 1) / 5) % 4) + 1}`
    nodes.push({ id: `t${step}`, type: 'task', lane_id: lane, name: `Purchase step ${step}` })
    edges.push({ id: `f${step}`, source: previous, target: `t${step}`, ...(previous.startsWith('g') ? { label: 'Yes' } : {}) })
    previous = `t${step}`
    if (step % every === 0 && step < activities) {
      nodes.push({ id: `g${step}`, type: 'exclusive_gateway', lane_id: lane, name: `Step ${step} approved?` })
      nodes.push({ id: `x${step}`, type: 'end_event', lane_id: lane, name: `Cancelled at ${step}` })
      edges.push({ id: `f${step}-g`, source: `t${step}`, target: `g${step}` }, { id: `f${step}-no`, source: `g${step}`, target: `x${step}`, label: 'No' })
      previous = `g${step}`
    }
  }
  nodes.push({ id: 'end', type: 'end_event', lane_id: 'l4', name: 'Purchase closed' })
  edges.push({ id: 'f-end', source: previous, target: 'end' })
  return { version: 1, lanes, nodes, edges }
}

export function partners () {
  return strip({
    version: 1,
    lanes: [
      { id: 'c', name: 'Customer', kind: 'external', order: 1 },
      { id: 'a', name: 'Sales', order: 2 },
      { id: 'b', name: 'Billing', order: 3 },
      { id: 'k', name: 'Bank', kind: 'external', order: 4 }
    ],
    nodes: [
      { id: 'c1', type: 'send_task', lane_id: 'c', name: 'Send order' },
      { id: 's', type: 'start_event', lane_id: 'a', name: 'Order received', event_definition: { kind: 'message' } },
      { id: 't1', type: 'task', lane_id: 'a', name: 'Check stock' },
      { id: 't2', type: 'task', lane_id: 'b', name: 'Issue invoice' },
      { id: 't3', type: 'receive_task', lane_id: 'b', name: 'Receive payment' },
      { id: 'k1', type: 'task', lane_id: 'k', name: 'Confirm transfer' },
      { id: 'e', type: 'end_event', lane_id: 'b', name: 'Order paid' }
    ],
    edges: [
      { id: 'm1', type: 'message_flow', source: 'c1', target: 's' },
      { id: 'f1', source: 's', target: 't1' }, { id: 'f2', source: 't1', target: 't2' },
      { id: 'f3', source: 't2', target: 't3' }, { id: 'm2', type: 'message_flow', source: 'k1', target: 't3' },
      { id: 'f4', source: 't3', target: 'e' }
    ]
  })
}

export const FIXTURES = { invoice, rework, parallel, large, partners }
