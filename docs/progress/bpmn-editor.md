# Bali::BpmnEditor — progreso (#1489)

Documento de trabajo del componente. Se actualiza al cerrar cada fase (`[BPMN Fx]`). Está en
español porque es prosa para el equipo, como el CHANGELOG; puede pasar al cuerpo del PR y
borrarse antes de fusionar.

## F0 · Diagnóstico y plan

### Lo que hay

- **Precedente en Bali:** `Bali::Gantt` (isla de React Flow). Se copia su forma completa:
  `Component` + `Data` (valida el contrato y levanta `InvalidError`), `Translations` (tabla plana
  servida desde `bali_view.*.island`, con `KEYS` espejo de `i18n.js`), controlador
  `ReactIslandController` que carga React en `loadComponent()`, tres subrutas npm
  (`./bpmn-editor`, `-entry`, `-loader`), esqueleto + `<noscript>` dentro del montaje,
  `urls:` con llaves validadas, `openDrawerUrl` para los drawers de la app y regla «el servidor
  manda» (el `200` trae el documento completo).
- **Editor de Gobierno Corporativo** (`ProcessFlowEditor.jsx`, ~4.3k líneas con `bpmn/**`).
  Una petición por operación (~30 URLs), estado en nodos de React Flow, modales de negocio.
  Se reutiliza **como diseño, no como código**:
  - `laneGeometry.js`: el mapa de ejes por orientación (`LANE_AXES`: eje principal donde se
    apilan los carriles y eje cruzado donde se extienden), el ancho común de carriles, el
    desplazamiento del conjunto (`poolOffset`) con coordenadas de los nodos relativas al pool, y
    la heurística de arrastre de carril (centro dentro de otro carril = intercambio; si no,
    mover el conjunto).
  - `edgeGeometry.js`/`FloatingEdge`: salir por el lado más cercano. Se reemplaza por el ruteo
    ortogonal que rodea elementos (ver decisiones).
  - `LaneNode`: encabezado como zona de arrastre y dos controles de tamaño (eje principal y
    eje cruzado, éste común a todos).
  - Nodos (`ActivityNode`, gateways, eventos): se redibujan en SVG para soportar el catálogo
    completo de BPMN.
  - `useFullscreen`, `useSaveStatus`: misma idea, reescritos.
  - **Fuera:** URLs por entidad, `LaneModal` (titulares Workday/MDM), `NewSubordinateModal`,
    `isProcedure`, «hijos sin diagramar» con textos de dominio, restricción de hijo directo,
    `dagre` (dependencia de la app).
- **Prototipo de diseño** (`PxEditor`, `pxModel`, `PxPalette`): referencia de comportamiento:
  menú rápido con dirección, insertar sobre una conexión, renombrar en el lienzo, bloqueos con
  mensaje, panel de pendientes, compactar («Ajustar flujo») con carriles, ruteo ortogonal por
  candidatos, leyenda, paleta por grupos con marca «por confirmar», exportación BPMN y PNG con
  marca de agua.

### Arquitectura

**El documento es el estado.** El cliente guarda un solo objeto (el contrato del issue) y todas
las operaciones son funciones puras `documento → documento` (o un error con la llave del
mensaje). React Flow sólo dibuja e interactúa: los nodos de React Flow se derivan del
documento. Eso da deshacer y rehacer gratis (pilas de documentos), autoguardado del documento
completo y pruebas unitarias sin navegador.

```
app/components/bali/bpmn_editor/
  component.rb, component.html.erb   # montaje + esqueleto + noscript
  data.rb                            # contrato; InvalidError
  palette.rb                         # catálogo de llaves, presets, items/notes
  translations.rb                    # tabla i18n plana (KEYS ↔ i18n.js)
  preview.rb, previews/              # Lookbook
  index.js                           # BpmnEditorController (ReactIslandController)
  BpmnEditor.jsx                     # raíz de la isla
  model/                             # JS puro, probado con `node --test`
    catalog.js     # tipos BPMN, tamaños, grupos de paleta, presets
    geometry.js    # ejes, bandas de carril, cajas, carril en un punto
    routing.js     # ruteo ortogonal que rodea elementos
    operations.js  # crear, mover, conectar, borrar, carriles, alinear, insertar…
    layout.js      # auto-layout y «Ajustar flujo» (con y sin carriles)
    rules.js       # motor de reglas + catálogo + registerBpmnRule
    history.js     # deshacer/rehacer
    saveClient.js  # PUT/GET/POST con 200/409/422
  (componentes JSX: nodos, carril, conexión, barras, paleta, leyenda, paneles)
app/frontend/bali/bpmn-editor{,-entry,-loader}.js
test/javascript/bpmn_editor/*.test.js   # node --test (sin dependencias nuevas)
```

### API

```erb
<%= render Bali::BpmnEditor::Component.new(
      data: FlowDiagram.new(@flow).to_h,          # Hash o Bali::BpmnEditor::Data
      editable: policy(@flow).edit_diagram?,
      read_only_notice: @flow.edit_blocked_reason,
      autosave: true,                             # false → botón «Guardar borrador»
      palette: { preset: :descriptive,            # :descriptive | :analytic | :full, o un Array de llaves
                 items: { complex_gateway: false, signal_event: "disabled" },
                 notes: { signal_event: "Por confirmar con el área" },
                 note_legend: "Contorno punteado: por confirmar" },
      legend: { remove: %i[external_task], add: [{ key: "rework", label: "Retrabajo", swatch: "issue" }] },
      rules: { disabled: %i[R17], enabled: %i[R12], severities: { R16: :warning },
               messages: { R06: "…" }, options: { min_lanes: 2, max_activities: 25 } },
      node_fields: { task: [{ key: "duration", label: "Duración", type: "number" }] },
      lane_fields: [{ key: "notes", label: "Notas", type: "textarea" }],
      urls: { save:, diagram:, finalize:, references:, new_reference:,
              lane_assignees:, new_lane_assignee:, import: },
      i18n: nil, id: dom_id(@flow, :bpmn)) %>
```

Sin `editable:` o sin `urls[:save]` es un visor (solo lectura).

**Contrato de datos:** el del issue, con tres precisiones:

- `x`, `y` de cada nodo son la esquina superior izquierda **relativa al origen del pool**;
  mover el conjunto sólo cambia `pool.x/y`.
- `pool.length` (opcional): largo común de los carriles sobre el eje del flujo, cuando el
  usuario lo agranda a mano. Sin él se calcula de los nodos.
- `edges[].type`: `sequence_flow` (por omisión), `message_flow` o `association`.

Los tipos de nodo siguen los nombres de BPMN en snake_case (`task`, `user_task`, `sub_process`,
`exclusive_gateway`, `start_event`, `intermediate_catch_event`, `end_event`, `data_object`…) y
los eventos llevan `event_definition.kind`. Un tipo desconocido se conserva y se dibuja como caja
genérica.

**Contrato de mutación:** el del issue. `POST urls[:finalize]` manda `{ diagram, version }`
para que lo finalizado sea exactamente lo que se ve.

### Riesgos

1. **Alcance.** F0–F8 es mucho; se cierran fases completas y en orden.
2. **Rendimiento del ruteo** con >50 actividades: se calcula una vez por cambio del documento y,
   al arrastrar, sólo para las conexiones de los nodos que se mueven.
3. **React Flow controlado** con nodos que no son hijos del carril: se evita `parentId`; los
   carriles son nodos de fondo y la pertenencia se decide por geometría al soltar.
4. **Español en el repo:** la regla del repo (`.claude/CLAUDE.md`) pide inglés en código,
   comentarios y pruebas. Los textos de la UI van en `config/locales/bali_view.es.yml` (y en),
   como el Gantt; los previews de Lookbook pasan el locale `es`.
5. **No hay pruebas JS unitarias en el repo.** Se usa `node --test` (incluido en Node, sin
   dependencias nuevas) sobre los módulos puros de `model/`.

## Decisiones

- **Ruteo propio, no elkjs.** elkjs pesa ~1.4 MB, es asíncrono (worker) y resuelve layout de
  grafos completos; aquí se necesita rutear una conexión entre cajas fijas, al vuelo, mientras se
  arrastra. El ruteo por candidatos ortogonales del prototipo (≈150 líneas, puertos fijos o
  automáticos, penaliza dobleces, descarta segmentos que cruzan cajas) cubre el criterio «la
  línea no pasa por encima de otros elementos» y no suma peso.
- **Auto-layout propio** (capas por camino más largo, orden por baricentro) en lugar de dagre:
  funciona también con carriles («Ajustar flujo») porque respeta el carril de cada nodo.
- **Reglas:** se conservan los IDs R01–R26 de la fuente para que la app los reconozca. Las del
  catálogo estándar del issue van activas; las opcionales del issue (R12, R14, R15, R16, R17,
  R19) y R04/R20 (de dominio) van desactivadas. Las nuevas de buenas prácticas BPMN llevan
  prefijo `B` y van como advertencia (o desactivadas).
- **Presets de paleta:** `:descriptive` (subclase Descriptiva de BPMN 2.0 / Method and Style),
  `:analytic` (subclase Analítica) y `:full`.
- **Textos:** tabla i18n plana con respaldo en inglés en JS (como el Gantt); el locale `es` es
  el que se escribe primero.

- **`editable:` sin `urls[:save]` es solo lectura:** editar sin dónde guardar perdería el trabajo al
  recargar.
- **Atajos de teclado:** escuchan en `document` y responden si el foco está dentro del editor o en
  `<body>` y fue el último editor tocado (al borrar el nodo enfocado, el foco cae en `<body>`). Con
  varias instancias en pestañas sólo responde una.
- **Arrastre de carril:** si el centro del carril cae sobre otro carril, se reordena; si no, se
  mueve el conjunto (heurística del editor de Gobierno Corporativo).
- **Selección:** carriles y nodos no se mezclan en una selección; `elevateNodesOnSelect` va
  apagado porque un carril seleccionado taparía sus nodos.

## Fases

- [x] F0 Diagnóstico y plan
- [x] F1 Esqueleto — `Component`, `Data`, `Palette`, `Translations` (en/es), entries npm
  (`./bpmn-editor`, `-entry`, `-loader`), isla de solo lectura (carriles horizontales y
  verticales, nodos del catálogo completo dibujados en SVG, conexiones con ruteo ortogonal,
  etiquetas, minimapa, zoom con porcentaje, navegación a `reference.url`), auto-layout al cargar
  un documento sin coordenadas, previews (`default`, `vertical`, `large`, `empty`), pruebas Ruby y
  `node --test` (geometría, ruteo, layout). Muestras sintéticas en
  `test/dummy/app/models/bpmn_sample_flows.rb`.
- [x] F2 Paridad de edición — operaciones puras (`model/operations.js`): crear, mover (cambia de
  carril por el centro; el carril crece y los siguientes se recorren), conectar (con bloqueos y
  etiquetas Sí/No en el gateway exclusivo), reconectar, borrar (con carril con elementos y mínimo de
  carriles bloqueados), carriles (agregar, renombrar en el encabezado, reordenar arrastrando el
  encabezado o con Subir/Bajar, redimensionar con largo común, mover el conjunto), orientación,
  auto-layout. Historial (`model/history.js`), autoguardado del documento completo con versión
  (`hooks/useSaver.js`: 200, 409 → recarga y aviso, 422 → errores), indicador de guardado, aviso del
  navegador al salir, modo Navegar, pantalla completa, zoom con porcentaje, minimapa, atajos
  (Ctrl+Z/Y/A, Supr, Esc, flechas). Implementación de referencia en `test/dummy`
  (`ProcessFlow`, `Admin::ProcessFlows::DiagramsController` y `FinalizationsController`, página
  `/admin/process_flows/:id`) y preview `editable`. Verificado en el navegador con Playwright
  (crear, mover, deshacer/rehacer, bloqueo de conexión, renombrar, reordenar carriles,
  orientación, auto-layout, 409).
- [ ] F3 Paleta, leyenda y carril externo
- [ ] F4 Reglas, pendientes y Borrador/Finalizar
- [ ] F5 Edición rápida
- [ ] F6 Layout
- [ ] F7 Puntos de extensión
- [ ] F8 Notas, comparación, salidas, docs
