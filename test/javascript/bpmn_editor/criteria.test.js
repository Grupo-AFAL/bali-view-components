// The examples of AFAL's BPMN criteria matrix (Criterios BPMN Rev.01): for
// each criterion a rule checks, its «Uso incorrecto» must raise the rule and
// its «Uso correcto» must not. Names are the matrix's own, in Spanish, checked
// against the word lists the Spanish locale ships (bali_view.es.yml).
import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { evaluate, CATALOG } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../app/components/bali/bpmn_editor/model/rules/afal.js'
// The matrix's guidelines run as a host that imports them does.
import '../../../app/frontend/bali/bpmn-editor-afal-rules.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import { NODE_TYPES } from '../../../app/components/bali/bpmn_editor/model/catalog.js'

// The Spanish island table, read from the locale file the gem ships.
function spanish () {
  const lines = fs.readFileSync(new URL('../../../config/locales/bali_view.es.yml', import.meta.url), 'utf8').split('\n')
  const start = lines.indexOf('    bpmn_editor:')
  const table = {}
  let inside = false
  for (const line of lines.slice(start + 1)) {
    if (line === '      island:') { inside = true; continue }
    if (!inside) continue
    const match = line.match(/^ {8}([\w-]+): (".*")$/)
    if (!match) { if (!/^ {8}/.test(line) && line.trim()) break; continue }
    table[match[1]] = JSON.parse(match[2])
  }
  return table
}
const t = translator(spanish())
const ALL = { enabled: [...CATALOG.map((r) => r.id)] }

// A process over two lanes. `nodes`: [id, type, lane (1 or 2), name, extra];
// each one gets its own column, so nothing overlaps. `edges`: [source,
// target, label?, extra?].
function processOf (nodes, edges, { lanes = ['Solicitante', 'Área responsable'] } = {}) {
  return {
    version: 1,
    orientation: 'horizontal',
    pool: { x: 0, y: 0 },
    lanes: lanes.map((name, i) => ({ id: `l${i + 1}`, name, kind: 'internal', order: i + 1, size: 180 })),
    nodes: nodes.map(([id, type, lane, name, extra = {}], i) => {
      const { width, height } = NODE_TYPES[type] || { width: 150, height: 64 }
      return { id, type, lane_id: `l${lane}`, name, x: 100 + i * 200 - width / 2, y: (lane - 1) * 180 + 90 - height / 2, ...extra }
    }),
    edges: edges.map(([source, target, label, extra = {}], i) => ({ id: `f${i + 1}`, source, target, ...(label ? { label } : {}), ...extra }))
  }
}
const start = (name = 'Solicitud recibida', extra) => ['s', 'start_event', 1, name, extra]
const end = (id = 'e', name = 'Solicitud atendida', lane = 2) => [id, 'end_event', lane, name]
const task = (id, name, lane = 2) => [id, 'task', lane, name]
const gateway = (id, type, name = '', lane = 2, extra = {}) => [id, type, lane, name, extra]
const blue = (id, name = '¿Información completa?', lane = 2) => [id, 'exclusive_gateway', lane, name, { marker_visible: false }]
// Start → «Elaborar solicitud» (lane 1) → the rest (lane 2).
const head = ['s', 'a0']
const opening = [start(), task('a0', 'Elaborar la solicitud', 1)]
const linear = (names) => processOf(
  [...opening, ...names.map((n, i) => task(`a${i + 1}`, n)), end()],
  [head, ...names.map((_, i) => [`a${i}`, `a${i + 1}`]), [`a${names.length}`, 'e']]
)
// A decision `g` of `type` opening two branches that meet in `close` (a
// gateway type) before the end; `extra` adds branch content.
function splitAndClose (open, closeType, { labels = ['Sí', 'No'] } = {}) {
  return processOf(
    [...opening, open, task('b1', 'Registrar la solicitud'), task('b2', 'Notificar el rechazo'), gateway('j', closeType), end()],
    [head, ['a0', 'g'], ['g', 'b1', labels[0]], ['g', 'b2', labels[1]], ['b1', 'j'], ['b2', 'j'], ['j', 'e']]
  )
}

const CASES = [
  // ── Actividades ────────────────────────────────────────────────────────
  { codes: ['ACT-01', 'ACT-07'], rules: ['ACT-07'], wrong: () => linear(['Recibir la solicitud', 'Registrar la solicitud']), right: () => linear(['Registrar la solicitud']) },
  { codes: ['ACT-02'], rules: ['ACT-02'], wrong: () => linear(['Validación de documentos']), right: () => linear(['Registrar los documentos']) },
  { codes: ['ACT-03'], rules: ['ACT-03'], wrong: () => linear(['Realizar gestión correspondiente']), right: () => linear(['Registrar la solicitud']) },
  { codes: ['ACT-04'], rules: ['ACT-03'], wrong: () => linear(['Dar clic en Guardar']), right: () => linear(['Registrar la solicitud']) },
  { codes: ['ACT-05'], rules: ['ACT-03'], wrong: () => linear(['Revisar, autorizar y registrar solicitud']), right: () => linear(['Calcular el monto a pagar']) },
  { codes: ['ACT-06'], rules: ['R16'], wrong: () => linear(['Registrar solicitud', 'Registrar solicitud']), right: () => linear(['Registrar solicitud']) },
  { codes: ['ACT-08'], rules: ['ACT-07'], wrong: () => linear(['Enviar solicitud al gerente']), right: () => linear(['Registrar la solicitud']) },
  { codes: ['ACT-09'], rules: ['ACT-09'], wrong: () => linear(['Dar seguimiento a la solicitud']), right: () => linear(['Actualizar el registro']) },
  { codes: ['ACT-09'], rules: ['ACT-09'], wrong: () => linear(['Mantener actualizado el expediente']), right: () => linear(['Actualizar el expediente']) },
  ...[['ACT-10', 'Validar la documentación', '¿Documentación válida?'], ['ACT-11', 'Revisar la solicitud', '¿Solicitud correcta?'], ['ACT-12', 'Autorizar la solicitud', '¿Solicitud autorizada?']].map(([code, name, question]) => ({
    codes: [code],
    rules: ['ACT-10'],
    wrong: () => linear([name, 'Registrar la solicitud']),
    right: () => processOf(
      [...opening, task('v', name), blue('g', question), task('b1', 'Registrar la solicitud'), end('e'), end('x', 'Solicitud rechazada')],
      [head, ['a0', 'v'], ['v', 'g'], ['g', 'b1', 'Sí'], ['g', 'x', 'No'], ['b1', 'e']])
  })),
  // Rework: back to «Calcular» directly (wrong) or through a merging XOR (right).
  ...['ACT-13', 'COM-22', 'EST-04'].map((code) => ({
    codes: [code],
    rules: ['COM-22'],
    wrong: () => processOf(
      [...opening, task('c', 'Calcular el monto'), task('v', 'Validar el cálculo'), blue('g', '¿Cálculo correcto?'), end()],
      [head, ['a0', 'c'], ['c', 'v'], ['v', 'g'], ['g', 'e', 'Sí'], ['g', 'c', 'No']]),
    right: () => processOf(
      [...opening, gateway('m', 'exclusive_gateway'), task('c', 'Calcular el monto'), task('v', 'Validar el cálculo'), blue('g', '¿Cálculo correcto?'), end()],
      [head, ['a0', 'm'], ['m', 'c'], ['c', 'v'], ['v', 'g'], ['g', 'e', 'Sí'], ['g', 'm', 'No']])
  })),

  // ── Eventos de inicio ──────────────────────────────────────────────────
  { codes: ['EVI-01'], rules: ['R12'], wrong: () => processOf([task('a0', 'Elaborar la solicitud', 1), task('a1', 'Registrar la solicitud'), end()], [['a0', 'a1'], ['a1', 'e']]), right: () => linear(['Registrar la solicitud']) },
  { codes: ['EVI-02'], rules: ['R06'], wrong: () => { const d = linear(['Registrar la solicitud']); d.nodes[0].name = 'Inicio'; return d }, right: () => { const d = linear(['Registrar la solicitud']); d.nodes[0].name = 'Periodo de cierre iniciado'; return d } },
  { codes: ['EVI-03'], rules: ['EVI-03'], wrong: () => { const d = linear(['Registrar la solicitud']); d.nodes[0].name = 'Recibir solicitud'; return d }, right: () => linear(['Registrar la solicitud']) },
  {
    codes: ['EVI-05'],
    rules: ['EVI-05'],
    wrong: () => { const d = linear(['Registrar la póliza']); d.nodes[0].name = 'Cierre mensual'; return d },
    right: () => { const d = linear(['Registrar la póliza']); d.nodes[0] = { ...d.nodes[0], name: 'Inicio del cierre mensual', event_definition: { kind: 'timer' } }; return d }
  },
  { codes: ['EVI-06'], rules: ['R24'], wrong: () => { const d = linear(['Registrar la solicitud']); d.edges.push({ id: 'x', source: 'a1', target: 's' }); return d }, right: () => linear(['Registrar la solicitud']) },

  // ── Eventos intermedios ────────────────────────────────────────────────
  ...[['EVM-04', 'message', 'Mensaje', 'Confirmación de pago recibida'], ['EVM-06', 'timer', 'Tiempo', '3 meses después de la apertura']].map(([code, kind, wrong, right]) => ({
    codes: [code],
    rules: ['R08'],
    wrong: () => withEvent(kind, wrong),
    right: () => withEvent(kind, right)
  })),
  { codes: ['EVM-09'], rules: ['EVI-03'], wrong: () => withEvent('conditional', 'Validar que exista presupuesto'), right: () => withEvent('conditional', 'Presupuesto disponible') },
  {
    codes: ['EVM-01', 'VIS-10'],
    rules: ['VIS-10'],
    allowed: new Set(['task', 'start_event', 'end_event', 'timer_event', 'message_event', 'conditional_event']),
    wrong: () => withEvent('signal', 'Señal de cierre recibida'),
    right: () => withEvent('message', 'Confirmación de pago recibida')
  },

  // ── Diseño y legibilidad ───────────────────────────────────────────────
  // Forty activities in one row print far under the legible size on letter;
  // two fit (each column of processOf is 200 px: start, three steps, end).
  {
    codes: ['VIS-02', 'VIS-08'],
    rules: ['VIS-02'],
    wrong: () => linear(Array.from({ length: 40 }, (_, i) => `Registrar el paso ${i + 1}`)),
    right: () => linear(['Registrar la solicitud'])
  },

  // ── Eventos de fin ─────────────────────────────────────────────────────
  { codes: ['EVF-01'], rules: ['R13', 'EST-01'], wrong: () => processOf([...opening, task('a1', 'Registrar la solicitud')], [head, ['a0', 'a1']]), right: () => linear(['Registrar la solicitud']) },
  { codes: ['EVF-02'], rules: ['R07'], wrong: () => { const d = linear(['Presentar la declaración']); d.nodes.at(-1).name = 'Fin'; return d }, right: () => { const d = linear(['Presentar la declaración']); d.nodes.at(-1).name = 'Declaración anual presentada'; return d } },
  { codes: ['EVF-03'], rules: ['EVI-03'], wrong: () => { const d = linear(['Registrar la solicitud']); d.nodes.at(-1).name = 'Enviar notificación'; return d }, right: () => { const d = linear(['Registrar la solicitud']); d.nodes.at(-1).name = 'Notificación enviada'; return d } },
  {
    codes: ['EVF-04'],
    rules: ['EVF-04'],
    wrong: () => decided('Solicitud procesada', 'Solicitud procesada'),
    right: () => decided('Solicitud autorizada', 'Solicitud rechazada')
  },
  { codes: ['EVF-05'], rules: ['R24'], wrong: () => { const d = linear(['Registrar la solicitud']); d.edges.push({ id: 'x', source: 'e', target: 'a1' }); return d }, right: () => linear(['Registrar la solicitud']) },

  // ── Compuertas ─────────────────────────────────────────────────────────
  {
    codes: ['COM-02'],
    rules: ['COM-02'],
    wrong: () => processOf([...opening, blue('g'), task('b1', 'Registrar la solicitud'), task('b2', 'Completar la información'), end('e'), end('x', 'Solicitud cancelada')],
      [head, ['a0', 'g'], ['g', 'b1', 'Sí'], ['g', 'b2', 'No'], ['g', 'x', 'Cancelar'], ['b1', 'e'], ['b2', 'e']]),
    right: () => decided('Solicitud autorizada', 'Solicitud rechazada')
  },
  { codes: ['COM-06', 'DEC-01'], rules: ['R09'], wrong: () => decided('Solicitud autorizada', 'Solicitud rechazada', ''), right: () => decided('Solicitud autorizada', 'Solicitud rechazada') },
  { codes: ['COM-07', 'DEC-02'], rules: ['R03'], wrong: () => decided('Solicitud autorizada', 'Solicitud rechazada', undefined, ['', '']), right: () => decided('Solicitud autorizada', 'Solicitud rechazada') },
  {
    codes: ['COM-08'],
    rules: ['R09'],
    wrong: () => splitAndClose(gateway('g', 'inclusive_gateway', ''), 'inclusive_gateway', { labels: ['Fiscal', 'Legal'] }),
    right: () => splitAndClose(gateway('g', 'inclusive_gateway', '¿Qué validaciones aplican?'), 'inclusive_gateway', { labels: ['Fiscal', 'Legal'] })
  },
  {
    codes: ['COM-09'],
    rules: ['R03'],
    wrong: () => splitAndClose(gateway('g', 'exclusive_gateway', '¿Qué movimiento es?'), 'exclusive_gateway', { labels: ['', ''] }),
    right: () => splitAndClose(gateway('g', 'exclusive_gateway', '¿Qué movimiento es?'), 'exclusive_gateway', { labels: ['Alta', 'Baja'] })
  },
  {
    codes: ['COM-12'],
    rules: ['COM-12'],
    wrong: () => splitAndClose(gateway('g', 'parallel_gateway'), 'parallel_gateway'),
    right: () => splitAndClose(gateway('g', 'parallel_gateway'), 'parallel_gateway', { labels: ['', ''] })
  },
  { codes: ['COM-13', 'DEC-01'], rules: ['B11'], wrong: () => decided('Solicitud autorizada', 'Solicitud rechazada', 'Autorizar solicitud'), right: () => decided('Solicitud autorizada', 'Solicitud rechazada', '¿Solicitud autorizada?') },
  { codes: ['DEC-01'], rules: ['B11'], wrong: () => decided('Solicitud autorizada', 'Solicitud rechazada', 'Validación'), right: () => decided('Solicitud autorizada', 'Solicitud rechazada', '¿Documentación completa?') },
  {
    codes: ['COM-14', 'SEC-05'],
    rules: ['R01'],
    wrong: () => processOf([...opening, blue('g'), task('b1', 'Completar la información'), task('c', 'Registrar la solicitud'), end()],
      [head, ['a0', 'g'], ['g', 'c', 'Sí'], ['g', 'b1', 'No'], ['b1', 'c'], ['c', 'e']]),
    right: () => splitAndClose(blue('g'), 'exclusive_gateway')
  },
  { codes: ['COM-15'], rules: ['COM-19'], wrong: () => splitAndClose(blue('g'), 'parallel_gateway'), right: () => splitAndClose(blue('g'), 'exclusive_gateway') },
  { codes: ['COM-16'], rules: ['COM-19'], wrong: () => splitAndClose(gateway('g', 'exclusive_gateway', '¿Qué movimiento es?'), 'parallel_gateway', { labels: ['Alta', 'Baja'] }), right: () => splitAndClose(gateway('g', 'exclusive_gateway', '¿Qué movimiento es?'), 'exclusive_gateway', { labels: ['Alta', 'Baja'] }) },
  { codes: ['COM-17', 'COM-19'], rules: ['COM-19'], wrong: () => splitAndClose(gateway('g', 'inclusive_gateway', '¿Qué validaciones aplican?'), 'exclusive_gateway', { labels: ['Fiscal', 'Legal'] }), right: () => splitAndClose(gateway('g', 'inclusive_gateway', '¿Qué validaciones aplican?'), 'inclusive_gateway', { labels: ['Fiscal', 'Legal'] }) },
  { codes: ['COM-18'], rules: ['COM-19'], wrong: () => splitAndClose(gateway('g', 'parallel_gateway'), 'exclusive_gateway', { labels: ['', ''] }), right: () => splitAndClose(gateway('g', 'parallel_gateway'), 'parallel_gateway', { labels: ['', ''] }) },
  {
    // B1/B2 and A reach the outer merge directly (wrong); B1+B2 close first (right).
    codes: ['COM-20'],
    rules: ['COM-20'],
    wrong: () => nested(false),
    right: () => nested(true)
  },
  {
    // A path that ends in an end event needs no merge (only R05's correct use is checkable).
    codes: ['COM-21'],
    rules: ['R05'],
    wrong: () => processOf([...opening, gateway('g', 'parallel_gateway'), task('b1', 'Registrar la solicitud'), task('b2', 'Archivar el expediente'), end()],
      [head, ['a0', 'g'], ['g', 'b1'], ['g', 'b2'], ['b1', 'e'], ['b2', 'e']]),
    right: () => processOf([...opening, gateway('g', 'parallel_gateway'), task('b1', 'Registrar la solicitud'), task('b2', 'Archivar el expediente'), end('e'), end('x', 'Expediente archivado')],
      [head, ['a0', 'g'], ['g', 'b1'], ['g', 'b2'], ['b1', 'e'], ['b2', 'x']])
  },
  { codes: ['DEC-03'], rules: ['DEC-03'], wrong: () => decided('Solicitud autorizada', 'Solicitud rechazada', '¿Autorizado?', ['Continuar', 'Proceso']), right: () => decided('Solicitud autorizada', 'Solicitud rechazada', '¿Autorizado?') },

  // ── Flujos de secuencia ────────────────────────────────────────────────
  { codes: ['SEC-02'], rules: ['R25'], wrong: () => { const d = linear(['Registrar la solicitud']); d.edges.push({ id: 'x', source: 'a1', target: 'nada' }); return d }, right: () => linear(['Registrar la solicitud']) },
  { codes: ['SEC-04', 'EST-02'], rules: ['EST-01'], wrong: () => trapped(), right: () => decided('Solicitud autorizada', 'Solicitud rechazada') },

  // ── Procedimientos relacionados ────────────────────────────────────────
  ...[['SUB-05', ['', 'Proveedor registrado']], ['SUB-06', ['Solicitud de alta autorizada', '']], ['SUB-07', ['Alta de proveedor', 'Alta de proveedor']]].map(([code, labels]) => ({
    codes: [code],
    rules: ['SUB-05'],
    wrong: () => related(labels),
    right: () => related(['Solicitud de alta autorizada', 'Proveedor registrado'])
  })),
  {
    codes: ['SUB-09'],
    rules: ['R01'],
    wrong: () => { const d = related(['Solicitud de alta autorizada', 'Proveedor registrado']); d.edges.push({ id: 'x', source: 'a0', target: 'sp', label: 'Alta urgente' }); return d },
    right: () => related(['Solicitud de alta autorizada', 'Proveedor registrado'])
  },

  // ── Carriles ───────────────────────────────────────────────────────────
  { codes: ['LAN-07'], rules: ['R10'], wrong: () => processOf([start(), task('a0', 'Elaborar la solicitud', 1), task('a1', 'Registrar la solicitud', 1), end('e', 'Solicitud atendida', 1)], [head, ['a0', 'a1'], ['a1', 'e']]), right: () => linear(['Registrar la solicitud']) },
  { codes: ['LAN-08'], rules: ['LAN-08'], wrong: () => { const d = linear(['Registrar la solicitud']); d.lanes = [{ ...d.lanes[0], name: 'Gerente Jurídico' }, { ...d.lanes[1], name: 'Gte. Jurídico' }]; return d }, right: () => { const d = linear(['Registrar la solicitud']); d.lanes[0].name = 'Gerente Jurídico'; return d } },
  { codes: ['LAN-09'], rules: ['R21'], wrong: () => processOf([start(), task('a0', 'Elaborar la solicitud', 1), task('a1', 'Registrar la solicitud', 1), end('e', 'Solicitud atendida', 1)], [head, ['a0', 'a1'], ['a1', 'e']]), right: () => linear(['Registrar la solicitud']) },

  // ── Estructura ─────────────────────────────────────────────────────────
  { codes: ['EST-01'], rules: ['EST-01', 'R13'], wrong: () => trapped(), right: () => linear(['Registrar la solicitud']) },
  {
    codes: ['EST-05'],
    rules: ['EST-05'],
    wrong: () => processOf([...opening, gateway('m', 'exclusive_gateway'), task('c', 'Corregir la solicitud'), task('v', 'Revisar la corrección'), end()],
      [head, ['a0', 'm'], ['m', 'c'], ['c', 'v'], ['v', 'm']]),
    right: () => processOf([...opening, gateway('m', 'exclusive_gateway'), task('c', 'Corregir la solicitud'), blue('g', '¿Correcto?'), end()],
      [head, ['a0', 'm'], ['m', 'c'], ['c', 'g'], ['g', 'e', 'Sí'], ['g', 'm', 'No']])
  },

  { codes: ['LAN-02'], rules: ['R22'], wrong: () => { const d = linear(['Registrar la solicitud']); d.lanes[1].name = 'Carril 2'; return d }, right: () => linear(['Registrar la solicitud']) },
  { codes: ['LAN-06'], rules: ['R26'], wrong: () => { const d = linear(['Registrar la solicitud']); d.nodes[2].y = 150; return d }, right: () => linear(['Registrar la solicitud']) },
  { codes: ['COM-01'], rules: ['R02'], wrong: () => { const d = linear(['Registrar la solicitud']); d.edges.push({ id: 'x', source: 'a0', target: 'e' }); return d }, right: () => linear(['Registrar la solicitud']) },
  {
    codes: ['SUB-01'],
    rules: ['R11'],
    wrong: () => { const d = related(['Solicitud de alta autorizada', 'Proveedor registrado']); delete d.nodes.find((n) => n.id === 'sp').reference; return d },
    right: () => related(['Solicitud de alta autorizada', 'Proveedor registrado'])
  },

  // ── Diseño ─────────────────────────────────────────────────────────────
  { codes: ['VIS-07'], rules: ['R18'], wrong: () => { const d = linear(['Registrar la solicitud']); d.nodes[2].x = d.nodes[1].x + 20; d.nodes[2].lane_id = 'l1'; d.nodes[2].y = d.nodes[1].y; return d }, right: () => linear(['Registrar la solicitud']) }
]

// A plain flow with an intermediate event of `kind` before its end.
function withEvent (kind, name) {
  const type = kind === 'signal' || kind === 'message' || kind === 'timer' || kind === 'conditional' ? 'intermediate_catch_event' : 'intermediate_throw_event'
  return processOf([...opening, task('a1', 'Registrar la solicitud'), ['ev', type, 2, name, { event_definition: { kind } }], end()],
    [head, ['a0', 'a1'], ['a1', 'ev'], ['ev', 'e']])
}
// «¿Solicitud autorizada?» with two ends.
function decided (yesEnd, noEnd, question = '¿Solicitud autorizada?', labels = ['Sí', 'No']) {
  return processOf([...opening, blue('g', question), task('b1', 'Registrar la solicitud'), end('e', yesEnd), end('x', noEnd)],
    [head, ['a0', 'g'], ['g', 'b1', labels[0]], ['g', 'x', labels[1]], ['b1', 'e']])
}
// An open branch: «Más tarde» leads into a loop that never reaches an end.
function trapped () {
  const d = decided('Solicitud autorizada', 'Solicitud rechazada')
  d.nodes.push({ id: 'h', type: 'task', lane_id: 'l2', name: 'Retener la solicitud', x: 1400, y: 240 }, { id: 'k', type: 'task', lane_id: 'l2', name: 'Revisar la retención', x: 1600, y: 240 })
  d.nodes.find((n) => n.id === 'g').marker_visible = true
  d.edges.push({ id: 'x1', source: 'g', target: 'h', label: 'Más tarde' }, { id: 'x2', source: 'h', target: 'k' }, { id: 'x3', source: 'k', target: 'h' })
  return d
}
// A: «Registrar», B: an inner Yes/No with B1/B2, all meeting in the outer XOR.
function nested (closeInner) {
  const nodes = [...opening, gateway('g', 'exclusive_gateway', '¿Qué movimiento es?'), task('a', 'Registrar el alta'), blue('g2', '¿Proveedor conocido?'),
    task('b1', 'Actualizar el proveedor'), task('b2', 'Registrar el proveedor'), ...(closeInner ? [gateway('j2', 'exclusive_gateway')] : []), gateway('j', 'exclusive_gateway'), end()]
  const edges = [head, ['a0', 'g'], ['g', 'a', 'Alta'], ['g', 'g2', 'Cambio'], ['g2', 'b1', 'Sí'], ['g2', 'b2', 'No'], ['a', 'j'], ['j', 'e'],
    ...(closeInner ? [['b1', 'j2'], ['b2', 'j2'], ['j2', 'j']] : [['b1', 'j'], ['b2', 'j']])]
  return processOf(nodes, edges)
}
// A related procedure (+) with the labels of its way in and out.
function related ([into, out]) {
  return processOf([...opening, ['sp', 'sub_process', 2, 'Gestionar alta de proveedores', { reference: { id: '7', label: 'Gestionar alta de proveedores' } }], task('a1', 'Registrar la orden de compra'), end()],
    [head, ['a0', 'sp', into], ['sp', 'a1', out], ['a1', 'e']])
}

for (const c of CASES) {
  test(`${c.codes.join(', ')}: the matrix's wrong use raises ${c.rules.join(' or ')}, its right use does not`, () => {
    const issues = (d) => evaluate(d, ALL, t, { allowed: c.allowed, page: c.page }).filter((i) => c.rules.includes(i.rule))
    assert.ok(issues(c.wrong()).length > 0, 'the wrong use is flagged')
    assert.deepEqual(issues(c.right()).map((i) => `${i.rule}: ${i.message}`), [], 'the right use passes')
  })
}

test('every criterion a rule cites has an example here', () => {
  const covered = new Set(CASES.flatMap((c) => c.codes))
  const missing = [...new Set([...CATALOG, ...AFAL_RULES].flatMap((rule) => rule.criteria || []))].filter((code) => !covered.has(code))
  assert.deepEqual(missing, [])
})
