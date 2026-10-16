# Bali::BpmnEditor::Component

A BPMN 2.0 diagram editor with lanes: a React Flow island built exactly like
[`Bali::Gantt`](gantt.md). **Bali knows BPMN; the app knows its business.** The
component takes one document, saves the whole document back to the app, checks
modelling rules, and reaches the app through drawers, remote searches and
events. It knows nothing about positions, departments, approval flows or the
states of the app's records.

A diagram that only reads passes no `urls:` and no `editable:` — the same
island, with the editing chrome gone.

- Data contract and validation: `Bali::BpmnEditor::Data` (start there).
- Island mechanics: [react-island.md](react-island.md).
- Executable reference for every endpoint below: `test/dummy/app/controllers/admin/process_flows/`,
  `test/dummy/app/models/process_flow.rb` and the page `/admin/process_flows/:id`.

---

## Installation

The same four steps as the Gantt.

```bash
yarn add react react-dom @xyflow/react @rails/request.js
```

All four are **optional peers**: an app that never mounts the editor does not
install them. No layout or routing library is needed — both are Bali's own.

```js
// app/javascript/bpmn-editor-island.js — a dedicated bundler entry
import 'bali-view-components/bpmn-editor-entry'
```

```js
// esbuild.config.mjs
entryPoints: ['app/javascript/application.js', 'app/javascript/bpmn-editor-island.js']
```

```js
// app/javascript/application.js — weighs nothing, loads the entry on first sight
import 'bali-view-components/bpmn-editor-loader'
```

```erb
<%# layout <head> %>
<%= react_island_meta_tags('bpmn-editor', js: 'bpmn-editor-island.js', css: 'bpmn-editor-island.css') %>
```

The entry also installs the `bali_bpmn_event` Turbo Stream action (see
[Extension points](#extension-points)).

---

## Usage

```erb
<% if (reason = @flow.edit_blocked_reason) %>
  <%= render Bali::Notification::Component.new(type: :info) { reason } %>
<% end %>
<%= render Bali::BpmnEditor::Component.new(
      data: FlowDiagram.new(@flow).to_h,
      editable: policy(@flow).edit_diagram?,
      palette: { preset: :analytic, notes: { signal_event: "Pending confirmation" } },
      rules: { disabled: %i[R16], severities: { R11: :error }, options: { min_lanes: 3 } },
      fields: { nodes: FlowDiagram.node_fields, lanes: FlowDiagram.lane_fields },
      name: @flow.name,
      watermark: (@flow.draft? ? "Borrador" : nil),
      urls: {
        save: flow_diagram_path(@flow),
        diagram: flow_diagram_path(@flow),
        finalize: flow_diagram_finalization_path(@flow),
        references: flow_reference_options_path(@flow),
        new_reference: new_flow_reference_path(@flow),
        lane_assignees: flow_lane_assignee_options_path(@flow),
        new_lane_assignee: new_flow_lane_assignee_path(@flow),
        import: new_flow_bpmn_import_path(@flow)
      },
      id: dom_id(@flow, :bpmn)) %>
```

`FlowDiagram` is **your** serializer: the object that maps your tables to the
contract. `editable:` is yours to decide and the island only hides controls —
authorize every endpoint on the server anyway.

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `data:` | required | The document (`Hash` or `Bali::BpmnEditor::Data`) |
| `editable:` | `false` | May change the document. Without `urls[:save]` it stays read-only: there would be nowhere to save. Why it cannot be edited is the host's to say, with a `Bali::Notification` above it |
| `autosave:` | `true` | Save with a ~1.2 s debounce after each change. `false`: only the "Save draft" button saves |
| `lock_orientation:` | `false` | `true` keeps the document's own orientation (`data[:orientation]`, the one source of it) and the toolbar offers no switch — e.g. a host whose lanes are always horizontal |
| `external_lanes:` | `true` | Lanes may be marked as external participants (grey lane, white activities, joined by message flows). `false` hides that checkbox in the lane panel and the external entries of the default legend |
| `layout:` | `:compact` | How "Tidy up" (and the first layout of a document without coordinates) arranges the flow: `:compact` folds it to fit `page:` legibly, `:straight` keeps the happy path in one line — see [Layout](#layout). An unknown value raises |
| `page:` | `{ width: 8.5, height: 11, orientation: "landscape" }` | The sheet, in inches: the compact layout's target, and what the image, SVG and print outputs are laid on. `orientation:` is `"landscape"` or `"portrait"`; anything else, or a non-positive size, raises |
| `palette:` | `:descriptive` | A preset, an `Array` of keys (exactly those), or a `Hash` — see [Palette](#palette) |
| `legend:` | default entries | `{ add: [...], remove: [...] }`, a full `Array`, or `false` — see [Legend](#legend) |
| `rules:` | `{}` | `{ disabled:, enabled:, severities:, messages:, options: }` — see [Rules](#rules) |
| `fields:` | `{}` | `{ nodes: { type => [field] }, lanes: [field] }`, the properties panel's own fields — see [Fields](#fields). An unknown key raises |
| `urls:` | `{}` | `save`, `diagram`, `finalize`, `references`, `new_reference`, `lane_assignees`, `new_lane_assignee`, `import`. An unknown key raises |
| `name:` | `nil` | Title of the image and print outputs, the file names, the main participant of the `.bpmn` |
| `watermark:` | `nil` | Text across the image and print outputs, e.g. `"Borrador"` |
| `review:` | `{}` | `{ tags: [{ key:, label:, color: }], compare_with: { document:, label: } }`: the tags of the review notes and another version to compare against — see [Outputs, notes and comparison](#outputs-notes-and-comparison) |
| `i18n:` | `Translations.island` | Flat string table; Spanish and English ship with the gem, in the locale the component is built in |
| `id:` | generated | DOM id. The host's stream answers target it; generated (`bpmn-editor-<hex>`) when omitted, so two editors on one page never share one |

Any other option (`class:`, `aria:`…) lands on the wrapper element. `data:` is the document,
so HTML data attributes go on a wrapper of your own.

---

## The data contract

```jsonc
{
  "version": 12,                       // optimistic lock; the server bumps it
  "orientation": "horizontal",         // or "vertical"
  "status_label": "Borrador v0.3",     // shown as is; the editor interprets no states
  "pool": { "x": 0, "y": 0, "length": null },
  "lanes": [
    { "id": "l1", "name": "Accounts payable", "kind": "internal",   // internal | external
      "order": 1, "size": 180,
      "assignee": { "id": "position:42", "label": "Accounts payable", "group": "Position" },
      "fields": {} }
  ],
  "nodes": [
    { "id": "n1", "type": "user_task", "lane_id": "l1", "name": "Validate invoice",
      "documentation": "…", "x": 120, "y": 40, "width": 150, "height": 64,
      "reference": { "id": "77", "label": "Supplier onboarding", "url": "/…" },   // sub_process
      "event_definition": { "kind": "timer", "expression": "PT1H" },              // events
      "fields": {} }
  ],
  "edges": [ { "id": "e1", "source": "n1", "target": "n2", "type": "sequence_flow",
               "label": "Yes", "ports": { "source": "auto", "target": "left" }, "waypoints": [] } ],
  "annotations": [ { "id": "a1", "target_id": "n1", "number": 1, "text": "…", "tag": "keep" } ],
  "stencil": [ { "reference": { "id": "78", "label": "…", "url": "/…" } } ],
  "issues": [ { "rule": "APP1", "element_id": "n9", "severity": "error", "message": "…" } ]
}
```

- **Coordinates are pool-relative.** `x`/`y` is a node's top-left corner measured
  from the pool origin, so moving every lane at once only changes `pool.x/y`.
- **Lanes stack** along the main axis (y for horizontal lanes, x for vertical ones)
  in `order`, each `size` thick, and share one length along the flow: computed from
  the nodes, or `pool.length` once the user stretches it.
- **Node types** follow BPMN element names in snake_case: `task`, `user_task`,
  `service_task`, `send_task`, `receive_task`, `script_task`,
  `business_rule_task`, `manual_task`, `sub_process`, `exclusive_gateway`,
  `parallel_gateway`, `inclusive_gateway`, `complex_gateway`,
  `event_based_gateway` (`instantiate`, `event_gateway_type: "parallel"`),
  `start_event`, `intermediate_catch_event`, `intermediate_throw_event`,
  `end_event`, `text_annotation`, `group`, `data_object`, `data_collection`,
  `data_input`, `data_output`, `data_store`. Events carry `event_definition.kind`:
  `timer`, `message`, `conditional`, `signal`, `multiple`, `parallel_multiple`,
  `escalation`, `compensation`, `link`, `error`, `cancel`, `terminate`.
- **A type the island does not know is kept**: drawn as a dashed box and saved
  back untouched.
- **A document without coordinates is laid out on load** (the same layout as the
  toolbar's "Tidy up").
- **`stencil`** is the app's list of entities to place; **`issues`** are pending
  issues the server computed. Both are written by the server and never saved back.

`Data` raises `InvalidError` on structural problems (no id, duplicate ids, unknown
orientation, a coordinate that is not a number, an unknown edge type or port). It
does **not** raise on dangling references — an edge to a missing node, a node in a
missing lane — because those are modelling problems the editor lists as pending
issues (R25, R26), and an imported document has to open to be fixed.

---

## The save contract

The rule underneath: **the server is authoritative, and always answers with the
whole document.**

| Request | When | Answer |
|---|---|---|
| `PUT urls[:save]` `{ diagram:, version: }` | autosave (debounced), or "Save draft" | `200` the whole document with the new `version` and server `issues` · `409` stale version · `422` `{ errors: [...] }` |
| `GET urls[:diagram]` | after a 409, and on `bali-bpmn:reload` | `200` the whole document |
| `POST urls[:finalize]` `{ diagram:, version: }` | "Finalize flow", once the client found no errors and any save in flight is answered | `200` the whole document · `422` `{ errors:, issues:, version: }` |

- On a **409** the island fetches `urls[:diagram]`, replaces its document (history
  cleared) and tells the user someone else changed it.
- On a **422** the messages are shown and the change stays unsaved.
- A **200** replaces the local document — unless the user kept editing while the
  request was out: then only `version` and `issues` are taken and the newer local
  state is saved next.
- Undo and redo work on the client; each step is just one more `PUT`. The version
  travels apart from the document, so undoing never sends an old version.
- `diagram` omits `issues` and `stencil`; the server writes both.
- A finalize that fails still saved the draft, so its 422 carries the new `version`;
  without it the next save would answer 409.
- Requests go one at a time, and an answer to a request sent before a reload is ignored.

`test/dummy/app/controllers/admin/process_flows/diagrams_controller.rb` is the
reference: it validates through `Bali::BpmnEditor::Data`, answers 409 on a stale
version and returns `ProcessFlow#to_diagram`.

---

## Palette

```ruby
palette: :descriptive                      # default
palette: %i[start_event task exclusive_gateway end_event lane sequence_flow]
palette: { preset: :full,
           items: { complex_gateway: false, signal_event: "disabled" },
           notes: { signal_event: "Pending confirmation with the area" },
           note_legend: "Dotted outline: pending confirmation" }
```

Presets follow the conformance sub-classes of OMG BPMN 2.0 (§2), which are also the
levels of Bruce Silver's *BPMN Method and Style*:

- `:descriptive` — none/user/service task, sub-process, exclusive and parallel
  gateways, none/timer/message start, none/message/terminate end, lane, sequence
  and message flow, association, text annotation, group, data object and store.
- `:analytic` — adds the other task types, inclusive and event-based gateways, the
  intermediate events (timer, message, signal, conditional, link, escalation,
  compensation) and their start/end counterparts, data collections and data
  input/output.
- `:full` — every element, including the complex gateway and the multiple /
  parallel-multiple events.

`items:` adds (`true`), removes (`false`) or shows greyed (`"disabled"`) an item.
`notes:` marks an item with a dotted outline and puts the note in its tooltip;
`note_legend:` explains the mark at the foot of the palette, and `note_label:` names the
marked items in each group's header ("3 pending confirmation"). Keys:
`Bali::BpmnEditor::Palette::KEYS`.

## Legend

A collapsible legend floats over the canvas. Default entries: `task`,
`sub_process`, `external_lane`, `external_task`, `issue` — without the two external
ones under `external_lanes: false`.

```ruby
legend: { remove: %i[external_task],
          add: [ { key: "rework", label: "Rework", swatch: "color", color: "#dc2626" } ] }
legend: false
```

Swatches: `task`, `sub_process`, `gateway`, `start_event`, `end_event`,
`external_lane`, `external_task`, `issue`, `color` (needs `color:`). Review-note
tags in use are added automatically.

The related procedure (a collapsed sub-process with its [+]) is grey on the palette, the
canvas, the legend, the minimap and the outputs alike. Its colour is one CSS custom
property a host may set on the editor:

```css
.bali-bpmn-editor { --bpmn-sub-process: var(--color-secondary); }
```

---

## Rules

Every rule has an id, a severity (`error` / `warning`), the element it points at
and a message. **The draft always saves;** "Finalize flow" refuses while there is
an error. Messages come from the i18n table (`rule_<ID>`), interpolating `%{name}`.

Each key below changes a default: R16 is on and R17/R19 off out of the box, R11 is an
error, and the options default to 2 lanes and 25 activities.

```ruby
rules: { disabled: %i[R16], enabled: %i[R17 R19], severities: { R11: :warning },
         messages: { R06: "Name the trigger, not «%{name}»." },
         options: { min_lanes: 3, max_activities: 40 } }
```

The options are positive whole numbers; anything else raises.

On by default — the standard catalogue of #1489:

| ID | Rule | Source |
|---|---|---|
| R01 | An activity has at most one incoming sequence flow | bpmnlint `fake-join`; Method and Style |
| R02 | An activity has at most one outgoing sequence flow | bpmnlint `no-implicit-split` |
| R03 | Every outgoing flow of an exclusive/inclusive split has a label | Method and Style; bpmnlint `conditional-flows` |
| R05 | Paths of a parallel/inclusive split that meet again are merged by a gateway; a path that ends in an end event needs no merge | Method and Style; AFAL COM-21 |
| R06 | The start event names its trigger (not "Start") | Camunda modeling guidelines |
| R07 | Each end event names the end state (not "End") | Camunda modeling guidelines |
| R08 | A message or timer event names the communication or the term, not just its kind («Mensaje», «Tiempo»). No element needs a description: a decision's criterion is its name (R09, B11) | AFAL EVM-04, EVM-06 |
| R09 | Every flow element has a name (merging gateways exempt) | bpmnlint `label-required` |
| R10 | Every lane holds at least one activity | #1489 |
| R11 | A sub-process references something | #1489 |
| R12 | A start event and at least one end event | bpmnlint; AFAL EVI-01 |
| R13 | No disconnected element | bpmnlint `no-disconnected` |
| R16 | Distinct activity names | Method and Style; AFAL ACT-06 |
| R18 | No overlapping elements | #1489 |
| R21 | At least `min_lanes` lanes with activities (default 2): an empty lane is no participant | #1489; AFAL LAN-09 |
| R22 | Lanes have a specific name | Camunda modeling guidelines |
| R23 | Activities and gateways have a specific name | Camunda modeling guidelines |
| R24 | A start event has no incoming flow; an end event no outgoing | BPMN 2.0 §10.5 |
| R25 | No connection to a missing element | BPMN 2.0 §8.4.13 |
| R26 | Every flow element sits inside a lane (when there are lanes) | BPMN 2.0 §10.8 |
| B01 | An event-based gateway leads only to catching events or receive tasks, at least two | BPMN 2.0 §10.6.6; bpmnlint |
| B02 | A message flow joins different participants | BPMN 2.0 §9.3 |
| B03 | An association has an artifact or data element at one end | BPMN 2.0 §7.6 |
| B04 | No sequence flow touches an artifact or data element | BPMN 2.0 §8.4.13 |
| B05 | A link event has its pair (same name, other kind) | BPMN 2.0 §10.5.5; bpmnlint `link-event` |
| B06 | Error/cancel end events have no boundary to catch them at this level | BPMN 2.0 §10.5.3 |
| B08 | At most one blank start event | bpmnlint `single-blank-start-event` |
| B09 | No duplicate sequence flows | bpmnlint `no-duplicate-sequence-flows` |
| B10 | An instantiating event-based gateway has no incoming flow | BPMN 2.0 §10.6.6 |
| B11 | A decision (exclusive, Yes/No or inclusive split) is phrased as a question, and does not start with a verb («Autorizar solicitud») | Camunda modeling guidelines; AFAL COM-13, DEC-01 |

From AFAL's BPMN criteria matrix (Criterios BPMN Rev.01), the rules the matrix grounds
in BPMN 2.0, also on by default. Their id is the code of the criterion; `criteria` lists
every code a rule covers:

| ID | Rule | Criteria | Severity |
|---|---|---|---|
| COM-19 | A merge closes its split with the matching gateway: Yes/No → XOR, XOR → XOR, OR → OR, AND → AND (the opening is the merge's immediate dominator) | COM-15…COM-19 | error |
| COM-20 | Nested splits close from the inside out | COM-20 | error |
| COM-12 | A parallel split's outgoing flows carry no labels | COM-12 | error |
| COM-02 | The Yes/No decision has exactly two ways out (R03 asks for their labels) | COM-02, COM-07 | error |
| DEC-03 | The Yes/No decision's ways out answer its question (Yes / No) | DEC-03 | warning |
| EST-05 | Every cycle has a way out | EST-05 | error |
| EST-01 | Every element lies on a path from a start event to an end event | EST-01, EST-02, SEC-04, EVF-01 | error |
| VIS-10 | No element the host's palette does not offer (an imported diagram) | EVM-01, VIS-10 | error |
| EVI-03 | A start, end or conditional event names a fact or a state, not an action | EVI-03, EVF-03, EVM-09 | warning |
| EVI-05 | A plain start whose name speaks of a period («Cierre mensual») should be a timer start | EVI-05 | warning |

**AFAL's guidelines** — the matrix's criteria whose origin is «Lineamiento AFAL», not
BPMN 2.0 — are not in the editor's catalogue. They ship as an optional package that
registers them (`registerBpmnRule`); a host that follows AFAL's matrix imports it in the
**same bundle as the editor** — the island's own entry — so both share one rule registry:

```js
// app/javascript/bpmn-editor-island.js
import 'bali-view-components/bpmn-editor-entry'
import 'bali-view-components/bpmn-editor/afal-rules'
```

(With `registerBpmnEditor(application)` in the main bundle, import it there instead.)
Imported, they are on; `rules: { disabled: %i[ACT-02] }` still turns one off, and
`severities:`/`messages:` apply as to any rule. A host that does not import the package
never runs them, whatever `rules:` names — the editor warns in the console about a
configured id no rule has:

| ID | Rule | Criteria | Severity |
|---|---|---|---|
| COM-22 | A return to an earlier activity lands on a merging XOR placed before it, never on the activity nor on an AND | ACT-13, COM-22, EST-04 | error |
| EVF-04 | End events have distinct names | EVF-04 | error |
| SUB-05 | The flows into and out of a related procedure are labelled, and differ | SUB-05, SUB-06, SUB-07 | error |
| ACT-02 | An activity is worded as infinitive + object, not a noun («Validación de…») | ACT-02 | warning |
| ACT-07 | An activity does not only receive or pass on information («Recibir…», «Turnar…») | ACT-01, ACT-07, ACT-08 | warning |
| ACT-09 | No ongoing responsibility as an activity («Dar seguimiento», «Garantizar») | ACT-09 | warning |
| ACT-03 | No vague phrase, screen instruction («Dar clic») or several actions in one box | ACT-03, ACT-04, ACT-05 | warning |
| ACT-10 | Validating, reviewing, approving or authorizing is followed by a decision | ACT-10, ACT-11, ACT-12 | warning |
| LAN-08 | No two lanes with nearly the same name («Gerente Jurídico» / «Gte. Jurídico») | LAN-08 | warning |
| VIS-02 | The diagram is legible on its `page:` (11 px text printed at 6 pt or more) | VIS-02, VIS-08 | warning |

The «Rules» dialog groups every rule by the matrix's chapters and shows its criteria.
VIS-10 needs to know the palette: the editor passes the palette keys the host leaves
enabled (`palette:`); with no palette configured it checks nothing.

The B rules are warnings. Off by default: R14 (gateway that merges and splits), R15
(unnecessary gateway), R17 (verb + object), R19 (flow too large, `max_activities`),
R04 (Yes/No decision with more branches), R20 (`min_activities`), B07 (complex
gateway).

The word lists the naming and wording rules match are i18n entries, pipe-separated,
compared without accents or case, so they follow the language of the UI and a host
rewrites any of them through `i18n:`: `generic_*_names` and `vague_verbs` (R06, R07,
R08, R17, R22, R23), `action_verbs`, `infinitive_endings` (Spanish `ar|er|ir`; empty in
English, where only `action_verbs` counts) and `not_infinitives` (EVI-03, B11, ACT-02,
ACT-03), `nominal_endings` (ACT-02), `transition_verbs` (ACT-07), `continuous_phrases`
(ACT-09), `vague_phrases`, `operative_phrases` and `conjunctions` (ACT-03),
`decision_verbs` (ACT-10), `periodic_words` (EVI-05).

**Blocks on the spot** come from the same switches: with R01/R02 on, a connection
that breaks one-in/one-out is refused with a message; R26 refuses a drop outside a
lane, R21 deleting below the minimum of lanes, B02/B03/B04 the
wrong kind of connector. Deleting a lane that holds elements is always refused.
A document that already breaks a rule (an imported one) still opens and saves; the
problems are listed as pending, and only the edits made on it are checked.

**App rules** register from JavaScript, or come from the server in `issues`:

```js
import { registerBpmnRule } from 'bali-view-components/bpmn-editor'

registerBpmnRule({
  id: 'APP1',
  severity: 'warning',
  check: (doc) => doc.nodes.filter((n) => n.type === 'user_task' && !n.fields?.form)
    .map((n) => ({ element_id: n.id, message: `«${n.name}» needs a form.` }))
})
```

---

## Fields

The properties panel edits name and description, the timer expression, the
sub-process reference and the review notes. The app adds its own fields, stored
in the element's `fields`: per node type (`"*"` for every node) and for lanes.

```ruby
fields: {
  nodes: {
    "*" => [ { key: "owner_note", label: "Owner's note", type: "textarea" } ],
    user_task: [ { key: "duration", label: "Duration (minutes)", type: "number", min: 0 },
                 { key: "systems", label: "Systems", type: "multi_select", url: "/systems/options" } ]
  },
  lanes: [ { key: "notes", label: "Notes", type: "textarea" } ]
}
```

Types: `text`, `textarea`, `number`, `select`, `multi_select` (local `options:` or a
remote `url:` answering `[{ id, label }]`), `readonly`.

---

## Extension points

1. **Link a sub-process to an existing entity** — a remote search at
   `urls[:references]?q=` answering `[{ id, label, description, url, group }]`.
2. **Create the referenced entity** — "Create new" opens the app's drawer at
   `urls[:new_reference]?client_node_id=…&editor_id=…` (on its own when a
   sub-process is placed and there is no search). The app's form answers with:

   ```erb
   <%# create.turbo_stream.erb %>
   <%= bali_bpmn_reference_created(target: params[:editor_id], client_node_id: params[:client_node_id],
         reference: { id: procedure.id, label: procedure.name, url: procedure_path(procedure) }) %>
   ```

   The editor links the node and saves. Cancelled, the node stays unlinked and R11 lists it.
3. **Stencil** — the document's `stencil` shows as "To place"; dragging one creates a
   linked sub-process.
4. **Lane responsible** — a grouped search at `urls[:lane_assignees]?group=…&q=` (the
   groups are whatever `group` the app returns) and a drawer at `urls[:new_lane_assignee]`
   answered with `bali_bpmn_lane_assignee_created(target:, client_lane_id:, assignee:)`.
5. **Import BPMN** — the toolbar button opens `urls[:import]` in the drawer; when the
   app is done it answers `bali_bpmn_reload(target:)`.
6. **Navigation** — read-only, a click on a node with `reference.url` navigates;
   editing, a double-click does. The cancelable `bali-bpmn:open-reference` event comes
   first (`event.preventDefault()` to handle it yourself).

The helpers (`Bali::BpmnEditorHelper`) render the `bali_bpmn_event` Turbo Stream
action; without `target:` the event goes to `document` and reaches every editor.

### Events

Dispatched on the component element, bubbling:

| Event | `detail` |
|---|---|
| `bali-bpmn:dirty-change` | `{ dirty }` — mark a tab, warn before leaving |
| `bali-bpmn:saved` | `{ document }` |
| `bali-bpmn:finalized` | `{ document }` |
| `bali-bpmn:open-reference` | `{ node_id, reference }` — cancelable |

Listened for: `bali-bpmn:reload`, `bali-bpmn:reference-created`
(`{ client_node_id, reference }`), `bali-bpmn:lane-assignee-created`
(`{ client_lane_id, assignee }`).

Several flows in tabs: render one editor per `Bali::Tabs` panel, each with its own
`id:`, and listen for `dirty-change` on each. Leaving with unsaved changes: a full page
load gets the browser's warning; on a Turbo visit, with autosave the pending change is
sent at once, and without it the visitor is asked to confirm.

---

## Editing

- **Palette**: click an element and click inside a lane, or drag it. Over a sequence
  flow it is inserted into it — nothing disconnects, and what follows moves along.
- **Quick menu** next to the selected element: activity, intermediate event,
  gateway, end, or "More", towards any of four directions, already connected. When the
  spot ahead is taken the following elements move along; past the first or last lane,
  across the flow, that lane grows. A direction where nothing can go (into a lane header)
  is disabled, and its tooltip says why.
- **Branching**: an activity has one way in and one way out (R01/R02). Asked for a second
  way out, the quick menu offers "Split with: Decision (exclusive) · Parallel" (and
  Inclusive when the palette has it): the gateway goes after the activity, the existing way
  out passes through it, and the new element is its second branch — one undo step, its
  branch names left as pending (R03). When the way out already leads to a splitting
  gateway, the new element is one more branch of it. A connection drawn by hand that the
  rule refuses stays refused, and the notice offers "Add gateway", which does the same.
- **Lanes**: add, rename in the header (double-click), drag the header over another
  lane to reorder or elsewhere to move them all, resize one lane or the common length,
  mark external (grey lane, white activities).
- **Connections**: drag from a node's dot, or the "Connect" tool; drag an end to
  reconnect; pick exit/entry ports or "Recalculate route"; double-click a label to edit it.
  Routing is orthogonal and goes around elements; a label sits beside its line, next to
  where it leaves its source.
- **Selection**: Shift+click, Ctrl+A, "Select all", or "Box select" (for touch
  screens). Align vertically across lanes; horizontally only inside one lane.
- **Keyboard**: Ctrl+Z / Ctrl+Y (or Ctrl+Shift+Z), Ctrl+A, Delete/Backspace, Esc,
  arrows (10 px, Shift for 1 px). Shortcuts reach the editor last touched.
- **Local arrangement** (always on) and **Tidy up**: see [Layout](#layout).
- **Orientation**: horizontal ↔ vertical lanes, keeping lanes and reading order.

## Layout

The **local arrangement** runs after every edit that changes the structure (add, insert,
connect, move, delete, rename); neither the user nor the host can turn it off. It keeps what
the user placed where they placed it and only fixes what collides: an element whose footprint
— shape, name and pending badge — runs into another moves *forward along the flow*, and so do
the ones after it. A deletion that leaves a stretch of the flow wider than a column empty in
every lane closes it: what lies beyond moves back, all lanes together, and nothing before the
gap moves. Lanes grow and shrink to their content; connections are routed again. The edit and
its arrangement are one undo step, and the nodes slide into place (0.22 s) instead of jumping.
Typing in the properties panel, resizing lanes and moving the pool are not re-arranged.

**Tidy up** lays the whole diagram out again: a straight happy path, the branches of a split
symmetric around it, exceptions alternating below and above, aligned columns and uniform
spacing. Then it fits the view, clear of the toolbars and of the open legend or properties
panel. A fit never goes below **40 %**; a larger diagram opens at its start and scrolls.

With `layout: :compact` (the default) the columns fold into **bands**: the first reads left
to right, the next comes back right to left under it, and so on — the flow serpentines down
the lanes, which stay horizontal and whole, each holding one group of rows per band it takes
part in. Tidy up takes the fewest bands with which the diagram fits `page:` legibly, so a
diagram that fits straight stays straight; one that fits no way takes the band count that
shows it largest. A step on a returning band is a straight line out of the left side. Vertical
lanes are always laid out straight. `layout: :straight` keeps one band.

**Fits the page legibly** means the canvas' running text (names and labels, 11 px) prints at
**6 pt or more**: 11 px is 8.25 pt, so the diagram may shrink to 6 / 8.25 ≈ 0.73 of its size
inside the sheet's 10 mm margins, measured on what the image export draws (content, margins and
title). `model/page.js` (`pageFit`) computes it.

The canvas reserves no room for the **legend**: when the view settles with an element under
the open legend, it folds itself to its title. Opened again by hand, it stays open until the
view moves.

What is kept at zero after any operation:

- elements on top of each other; a flow element outside its lane or on its header;
- a connection through an element, an element's name or a pending badge;
- two connections sharing a stretch of line (parallel lines keep ≥ 12 px apart);
- labels on labels, lines or elements; a badge on a label;
- two branches of a gateway with up to three ways out leaving by the same side. The
  continuation in the gateway's own lane (with none, the branch most in line with it) leaves
  straight by the reading-direction side — right, or bottom in vertical lanes — and the others
  by the side towards their target. "Tidy up" keeps that continuation on the gateway's row
  even when the longest way ahead goes to another lane.

Conventions, and where they come from:

| Convention | Source |
|---|---|
| Orthogonal connections, as few bends and crossings as possible; a jump where two lines cross | Camunda best practices, *Creating readable process models* (avoid crossing flows) |
| The happy path in a straight line, left to right (top to bottom in vertical lanes) | Bruce Silver, *BPMN Method and Style* (2nd ed.) — the happy path; Camunda (model left to right, emphasize the happy path) |
| Splits drawn symmetrically | Camunda (model symmetrically) |
| A loop back runs under or over the flow, not through it | Camunda (avoid crossing flows); *Method and Style* |
| Flow in on the left/top side, out on the right/bottom; a gateway's branches leave by distinct corners, the straight one by the reading side | *Method and Style*; Camunda (model symmetrically) |
| Uniform element sizes, a 10 px grid, uniform spacing | *Method and Style* |
| Event names below the event, gateway names above it; a connection's label next to where it leaves its source | *Method and Style* (labeling); Camunda (labeling gateways and their outgoing flows) |
| Text annotations and data objects next to the element they belong to | *Method and Style* |
| Message flows between participants drawn vertically (horizontally in vertical lanes) | *Method and Style* (collaboration diagrams) |
| No overlapping elements | bpmnlint, `no-overlapping-elements` |
| Lanes fitted to their content | *Method and Style* |

The measurement behind this is `model/layoutQuality.js`; `test/javascript/bpmn_editor/`
runs it over five reference flows after Tidy up (both orientations) with these caps, and
over 200 random sequences of 30 edits (hard violations: 0, and no deletion leaves a stretch
wider than a column empty).

| Reference flow | Hard | Crossings | Avg. bends | Max. bends |
|---|---|---|---|---|
| Invoice (3 lanes, external participant) | 0 | 0 | ≤ 1 | ≤ 2 |
| Decision with rework | 0 | ≤ 1 | ≤ 1.5 | ≤ 4 |
| Three-branch parallel | 0 | 0 | ≤ 1 | ≤ 2 |
| 60 activities, 4 lanes | 0 | 0 | ≤ 1 | ≤ 2 |
| Two external participants | 0 | 0 | ≤ 1 | ≤ 2 |

## Outputs, notes and comparison

- **Download .bpmn**: BPMN 2.0 XML with diagram interchange. External lanes become
  participants of their own (message flows are only valid between participants);
  a referenced sub-process becomes a `callActivity` whose `calledElement` is the
  reference's `id` — an `xsd:QName`, so an id that does not start with a letter or `_`
  goes out prefixed (`101` → `_101`), like every other id in the file; an importer maps
  it back. Unknown types travel in a `bali:element` extension.
- **Download image (PNG) / SVG and Print**: the whole diagram, with the `name:` as title,
  `status_label` under it and the `watermark:` across. When it fits `page:` legibly it is laid
  on a sheet of that size, centred inside 10 mm margins and shrunk only as much as it must;
  otherwise it keeps its own size. Print uses the same sheet (`@page` of the page's size).
- **Review notes**: numbered markers on elements, a text and a tag from
  `review: { tags: }`, edited in the properties panel and saved in `annotations`.
- **Comparison**: with `review: { compare_with: }`, "Compare" shows what was added (green),
  removed (red) and changed (amber) — over one canvas or side by side — by element id.

---

## Accessibility

The canvas is mouse-first, like the Gantt's: keep a non-canvas path to what matters
(a list of activities, a form). What the island does carry: real buttons with
`aria-label`s and `aria-pressed` states, labelled groups, dialogs with
`aria-modal`, the pending panel and rules as lists, notices in live regions, visible
focus, documented shortcuts, and a `<noscript>` notice in the mount.

## Lookbook previews

| Preview | What it shows |
|---|---|
| `bali/bpmn_editor/default` | Read-only, horizontal lanes, an external participant |
| `bali/bpmn_editor/vertical` | Vertical lanes, laid out on load |
| `bali/bpmn_editor/editable` | The full editor against the dummy's endpoints; starts from the clean sample on each load (`fresh`, off to keep your edits) |
| `bali/bpmn_editor/configured` | Palette with disabled items and notes; legend with added/removed entries |
| `bali/bpmn_editor/review` | Review notes, comparison and the watermarked outputs |
| `bali/bpmn_editor/large` | 60 activities and 10 decisions over four lanes |
| `bali/bpmn_editor/empty` | An empty document |
| `bali/bpmn_editor/catalog` | Every palette element as its icon draws it and as the canvas does, with its name |

`/admin/process_flows/:id` in the dummy is the editor in a real layout, with the
drawers of the extension points working.
