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
<%= render Bali::BpmnEditor::Component.new(
      data: FlowDiagram.new(@flow).to_h,
      editable: policy(@flow).edit_diagram?,
      read_only_notice: @flow.edit_blocked_reason,
      palette: { preset: :analytic, notes: { signal_event: "Pending confirmation" } },
      rules: { disabled: %i[R17], severities: { R16: :warning }, options: { min_lanes: 2 } },
      node_fields: FlowDiagram.node_fields,
      lane_fields: FlowDiagram.lane_fields,
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
| `editable:` | `false` | May change the document. Without `urls[:save]` it stays read-only: there would be nowhere to save |
| `read_only_notice:` | `nil` | Why it cannot be edited; shown above a read-only diagram |
| `autosave:` | `true` | Save with a ~1.2 s debounce after each change. `false`: only the "Save draft" button saves |
| `palette:` | `:descriptive` | A preset, an `Array` of keys (exactly those), or a `Hash` — see [Palette](#palette) |
| `legend:` | default entries | `{ add: [...], remove: [...] }`, a full `Array`, or `false` — see [Legend](#legend) |
| `rules:` | `{}` | `{ disabled:, enabled:, severities:, messages:, options: }` — see [Rules](#rules) |
| `node_fields:` / `lane_fields:` | `{}` / `[]` | Field schemas for the properties panel — see [Fields](#fields) |
| `urls:` | `{}` | `save`, `diagram`, `finalize`, `references`, `new_reference`, `lane_assignees`, `new_lane_assignee`, `import`. An unknown key raises |
| `name:` | `nil` | Title of the image and print outputs, the file names, the main participant of the `.bpmn` |
| `watermark:` | `nil` | Text across the image and print outputs, e.g. `"Borrador"` |
| `annotation_tags:` | `[]` | Tags of the review notes: `[{ key:, label:, color: }]` |
| `compare_with:` | `nil` | `{ document:, label: }` — another version to compare against |
| `i18n:` | `Translations.island` | Flat string table; Spanish and English ship with the gem |
| `id:` | `nil` | DOM id. The host's stream answers target it |

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
- **A document without coordinates is laid out on load** (the same auto-layout as the
  toolbar button).
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
`sub_process`, `external_lane`, `external_task`, `issue`.

```ruby
legend: { remove: %i[external_task],
          add: [ { key: "rework", label: "Rework", swatch: "color", color: "#dc2626" } ] }
legend: false
```

Swatches: `task`, `sub_process`, `gateway`, `start_event`, `end_event`,
`external_lane`, `external_task`, `issue`, `color` (needs `color:`). Review-note
tags in use are added automatically.

---

## Rules

Every rule has an id, a severity (`error` / `warning`), the element it points at
and a message. **The draft always saves;** "Finalize flow" refuses while there is
an error. Messages come from the i18n table (`rule_<ID>`), interpolating `%{name}`.

```ruby
rules: { disabled: %i[R17], enabled: %i[R12 B07], severities: { R16: :warning },
         messages: { R06: "Name the trigger, not «%{name}»." },
         options: { min_lanes: 2, min_activities: 2, max_activities: 25 } }
```

On by default — the standard catalogue of #1489:

| ID | Rule | Source |
|---|---|---|
| R01 | An activity has at most one incoming sequence flow | bpmnlint `fake-join`; Method and Style |
| R02 | An activity has at most one outgoing sequence flow | bpmnlint `no-implicit-split` |
| R03 | Every outgoing flow of an exclusive/inclusive split has a label | Method and Style; bpmnlint `conditional-flows` |
| R05 | A parallel/inclusive split is merged by a gateway of its type | Method and Style |
| R06 | The start event names its trigger (not "Start") | Camunda modeling guidelines |
| R07 | Each end event names the end state (not "End") | Camunda modeling guidelines |
| R08 | Events and splitting gateways have a description | #1489 |
| R09 | Every flow element has a name (merging gateways exempt) | bpmnlint `label-required` |
| R10 | Every lane holds at least one activity | #1489 |
| R11 | A sub-process references something | #1489 |
| R13 | No disconnected element | bpmnlint `no-disconnected` |
| R18 | No overlapping elements | #1489 |
| R21 | At least `min_lanes` lanes (default 2) | #1489 |
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

The B rules are warnings. Off by default: R12 (a start and an end), R14 (gateway
that merges and splits), R15 (unnecessary gateway), R16 (repeated names), R17 (verb
+ object), R19 (flow too large, `max_activities`), R04 (Yes/No decision with more
branches), R20 (`min_activities`), B07 (complex gateway), B11 (exclusive split
phrased as a question).

The generic names R06/R07/R22/R23 look for, and the vague verbs of R17, are i18n
entries (`generic_*_names`, `vague_verbs`, pipe-separated), so they follow the
language of the UI.

**Blocks on the spot** come from the same switches: with R01/R02 on, a connection
that breaks one-in/one-out is refused with a message; R18 refuses an overlap, R26
a drop outside a lane, R21 deleting below the minimum of lanes, B02/B03/B04 the
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
in the element's `fields`:

```ruby
node_fields: {
  "*" => [ { key: "owner_note", label: "Owner's note", type: "textarea" } ],
  user_task: [ { key: "duration", label: "Duration (minutes)", type: "number", min: 0 },
               { key: "systems", label: "Systems", type: "multi_select", url: "/systems/options" } ]
},
lane_fields: [ { key: "notes", label: "Notes", type: "textarea" } ]
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
  spot ahead is taken the following elements move along; when there is no room it says
  so.
- **Lanes**: add, rename in the header (double-click), drag the header over another
  lane to reorder or elsewhere to move them all, resize one lane or the common length,
  mark external (grey lane, white activities).
- **Connections**: drag from a node's dot, or the "Connect" tool; drag an end to
  reconnect; pick exit/entry ports or "Recalculate route"; double-click a label to edit it.
  Routing is orthogonal and goes around elements; labels ride on their line.
- **Selection**: Shift+click, Ctrl+A, "Select all", or "Box select" (for touch
  screens). Align vertically across lanes; horizontally only inside one lane.
- **Keyboard**: Ctrl+Z / Ctrl+Y (or Ctrl+Shift+Z), Ctrl+A, Delete/Backspace, Esc,
  arrows (10 px, Shift for 1 px). Shortcuts reach the editor last touched.
- **Auto-layout / tidy the flow**: a layered layout that keeps every element in its lane.
- **Orientation**: horizontal ↔ vertical lanes, keeping lanes and reading order.

## Outputs, notes and comparison

- **Download .bpmn**: BPMN 2.0 XML with diagram interchange. External lanes become
  participants of their own (message flows are only valid between participants);
  a referenced sub-process becomes a call activity; unknown types travel in a
  `bali:element` extension.
- **Download image (PNG) / SVG and Print**: the whole diagram at full size, with the
  `name:` as title, `status_label` under it and the `watermark:` across.
- **Review notes**: numbered markers on elements, a text and a tag from
  `annotation_tags:`, edited in the properties panel and saved in `annotations`.
- **Comparison**: with `compare_with:`, "Compare" shows what was added (green),
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
| `bali/bpmn_editor/editable` | The full editor against the dummy's endpoints (`bin/rails db:seed`; edits persist) |
| `bali/bpmn_editor/configured` | Palette with disabled items and notes; legend with added/removed entries |
| `bali/bpmn_editor/review` | Review notes, comparison and the watermarked outputs |
| `bali/bpmn_editor/large` | 60 activities and 10 decisions over four lanes |
| `bali/bpmn_editor/empty` | An empty document |

`/admin/process_flows/:id` in the dummy is the editor in a real layout, with the
drawers of the extension points working.
