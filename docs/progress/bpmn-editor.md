# Bali::BpmnEditor — progreso (#1489)

Documento de trabajo del componente. Se actualiza al cerrar cada fase (`[BPMN Fx]`). Está en
español porque es prosa para el equipo, como el CHANGELOG; puede pasar al cuerpo del PR y
borrarse antes de fusionar.

**Avance: 100 %** (F0–F8 cerradas y revisión independiente aplicada).

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

- **Catálogo de reglas:** activas por omisión las del catálogo estándar del issue (R01–R03, R05–R11,
  R13, R18, R21–R26) y B01–B06, B08–B10 como advertencia. Desactivadas: las opcionales del issue
  (R12, R14, R15, R16, R17, R19), R04 y R20 (convenciones de dominio) y B07, B11 (estilo).
- **Gateways de cierre** quedan fuera de R08 y R09: no llevan decisión que nombrar ni describir
  (guías de Camunda; bpmnlint `label-required` los exige, aquí se relaja).
- **Participante externo:** un elemento de un carril externo conectado por flujo de mensaje no
  cuenta como desconectado (R13): el carril externo representa otro proceso.
- **R20 (mínimo de actividades)** es genérica (`options.min_activities`); el mínimo por nivel de
  jerarquía queda en la app.

## Arreglos heredados del editor de GC

Revisados los comentarios de `ProcessFlowEditor.jsx` y `components/bpmn/**`, y las pruebas
`test/javascript/bpmn/*` y `test/playwright/*` de Gobierno Corporativo.

| Arreglo o caso límite en GC | Estado en Bali |
|---|---|
| Etiquetas de conexión tapadas por los nodos al moverlos (`LABELLED_EDGE_Z_INDEX` > 1000 de `elevateNodesOnSelect`) | **Adaptado:** todas las conexiones van en `zIndex: 1` sobre los nodos y `elevateNodesOnSelect` está apagado, así que ningún nodo sube por encima de una etiqueta; además el ruteo rodea los nodos. |
| Etiqueta como `<text>` nativo en el SVG, no portal, para que no se desincronice | **Portado:** `RoutedEdge` dibuja la etiqueta dentro del SVG de la conexión. |
| `interactionWidth` amplio en las conexiones (trackpad) | **Portado:** 16 px (las rutas ortogonales son rectas; 30 px tapaba los puertos). |
| Ancho cruzado de todos los carriles sincronizado durante el arrastre (`onLaneResizing`) | **Portado:** `liveLength` en `BpmnEditor.jsx`; verificado en el navegador (los demás carriles siguen al arrastre). |
| `NodeResizeControl` se queda con la geometría vieja tras redimensionar (`updateNodeInternals` + `key`) | **Portado:** los controles se remontan con `key` por tamaño (`LaneNode.jsx`); los nodos llevan `measured` explícito. |
| Control de redimensionar centrado en el borde: la mitad cae en el carril vecino y éste lo tapa (commit 301b3a7e) | **Portado:** `flow.css` lo ancla dentro del carril, con cursores `ns-resize`/`ew-resize`; verificado con Playwright (el control queda dentro y responde). |
| `minHeight` / `minWidth` de carril para que no quede inutilizable | **Adaptado:** `MIN_LANE_SIZE` y `resizeLane` nunca dejan un carril más chico que su contenido. |
| TDZ y refs para que los handlers memorizados de carril llamen a la versión actual | **No aplica:** los carriles no guardan callbacks en `data`; leen el contexto del lienzo (`CanvasContext`) y las operaciones toman el documento actual de `docRef`. |
| El doble clic del carril no llega al `onDoubleClick` del DOM una vez que el carril es seleccionable | **No aplica:** el cuerpo del carril deja pasar el puntero y sólo el encabezado lo recibe; el doble clic en el encabezado renombra (verificado con Playwright). |
| Botón de editar del carril que no debe propagar el clic (commit 34113c79) | **No aplica:** no hay botón; se renombra en el encabezado y se edita en el panel. |
| Promover actividades al borrar un carril | **No aplica, por diseño del issue:** borrar un carril con elementos se **bloquea** con mensaje. |
| Auto-layout desactivado con carriles (dagre no conoce carriles) | **Resuelto distinto:** el auto-layout propio respeta el carril de cada nodo y funciona con carriles. |
| Coordenadas relativas al pool para que mover el conjunto no toque las de los nodos | **Portado** (contrato: `x`/`y` relativos al pool). |
| Arrastre de carril: intercambio si el centro cae en otro carril, si no mover el conjunto | **Portado** (`onNodeDragStop`). |
| Insertar el carril nuevo ANTES de las actividades para que no las tape | **Adaptado:** los carriles van en `zIndex: -20`, debajo de todo, y su cuerpo no recibe el puntero. |
| Al cambiar las dimensiones, escribir `width`/`height` y `style` a la vez | **No aplica:** los nodos se reconstruyen del documento con `width`, `height` y `measured`. |
| Salidas de un gateway paralelo sin etiqueta (regresión 9d17ef83) | **Portado:** la etiqueta se deshabilita en el panel y no se puede renombrar en el lienzo. |
| Etiqueta desde dos fuentes (`label` / `data.condition_label`) | **No aplica:** una sola fuente, `edge.label` del documento. |
| La expresión de tiempo sólo se envía en eventos de tiempo | **Adaptado:** el campo «Expresión» sólo aparece en eventos con `kind: "timer"`. |
| `fitView` al entrar y salir de pantalla completa | **Portado.** |
| Pantalla completa sobre el contenedor del editor (prueba de Playwright) | **Portado** y los diálogos se dibujan dentro del contenedor para seguir visibles. |
| Pruebas `laneGeometry`/`edgeGeometry` (lados, anclas, apilado, ancho común) | **Cubiertas** por `geometry.test.js`, `routing.test.js` y `operations.test.js`. |
| Pruebas de nodos (glifos de gateway, inicio/fin, terminación, subproceso navegable) | **Cubiertas** visualmente en los previews y en Cypress (montaje, carril externo); la forma es SVG compartida con la exportación. |

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
- [x] F3 Paleta, leyenda y carril externo — paleta por grupos plegables con contador y buscador,
  presets `:descriptive`/`:analytic`/`:full`, elementos habilitados, deshabilitados o con nota de la
  app (contorno punteado, nota en el tooltip y leyenda al pie); arrastrar o clic para colocar.
  Leyenda flotante plegable sobre el minimapa, configurable (`legend: { add:, remove: }`, `false`).
  Carril externo gris con actividades en blanco (casilla en el panel del carril) y lista de
  participantes con «PE». Preview `configured`.
- [x] F4 Reglas, pendientes y Borrador/Finalizar — motor desacoplado (`model/rules.js`): 26 reglas
  del catálogo (R01–R26) y 11 de buenas prácticas BPMN (B01–B11), cada una con fuente; activar,
  desactivar, cambiar severidad y reemplazar mensaje (`rules:`); reglas de la app con
  `registerBpmnRule` y pendientes del servidor (`issues`) mezclados sin duplicar. Botón «⚠ N
  pendientes», panel agrupado por severidad (el clic centra y resalta), diálogo «Reglas» con estado
  y fuente, triángulo en elementos y carriles. «Finalizar flujo» revisa errores en el cliente y
  luego hace `POST urls[:finalize]`; un 422 con `issues` abre el panel. Bloqueos inmediatos
  derivados de las reglas activas (`blockPolicy`). Pruebas: cada regla cumple e incumple
  (`rules.test.js`).
- [x] F5 Edición rápida — menú rápido junto al elemento seleccionado (Actividad, Evento, Gateway,
  Fin y «Más» con los elementos habilitados de la paleta) con dirección arriba/abajo/izquierda/
  derecha: crea el siguiente ya conectado; si adelante está ocupado recorre los siguientes, si no
  hay lugar dice «No fue posible crear el elemento en la dirección solicitada.». Insertar sobre una
  conexión (arrastrar desde la paleta o clic con la herramienta sobre la línea) sin desconectar.
  Deshacer/rehacer, atajos, renombrar con doble clic (nodo, carril y etiqueta), panel de propiedades
  con nombre, descripción, expresión de tiempo, referencia y campos `node_fields`/`lane_fields`
  (text, textarea, number, select, multi_select locales o remotos, readonly), arrastrar desde la
  paleta. Alineación de la selección (vertical entre carriles, horizontal sólo en el mismo carril).
- [x] F6 Layout — carriles que crecen y recorren a los siguientes al crear o mover, «Auto-layout /
  Ajustar flujo» por capas que respeta carriles (horizontal y vertical), Centrar, selección múltiple
  con Shift+clic, Ctrl+A, «Seleccionar todo» y modo «Selección múltiple» (arrastrar un recuadro,
  para pantallas táctiles), contador, alineación con bloqueo por cambio de participante o
  superposición, puertos de salida/entrada (Auto, Arriba, Derecha, Abajo, Izquierda) y «Recalcular
  ruta», reconexión arrastrando los extremos, ruteo ortogonal propio que rodea elementos y
  etiquetas sobre el segmento más largo de su línea, editables aparte con doble clic.
- [x] F7 Puntos de extensión — subproceso: búsqueda remota agrupada (`urls[:references]?q=`),
  «Crear nuevo» abre el drawer `urls[:new_reference]?client_node_id=…&editor_id=…` (se abre solo al
  colocar un subproceso cuando no hay búsqueda) y la app responde con
  `bali_bpmn_reference_created` (helper `Bali::BpmnEditorHelper`, acción de Turbo Stream
  `bali_bpmn_event`) → el nodo queda ligado. Responsable del carril: búsqueda agrupada con filtro por
  grupo (`urls[:lane_assignees]?group=&q=`) y drawer `urls[:new_lane_assignee]` con
  `bali_bpmn_lane_assignee_created`. `stencil`: panel «Por colocar», arrastrar crea el subproceso
  ligado. Navegación (clic en solo lectura, doble clic editando, evento cancelable
  `bali-bpmn:open-reference`). Eventos `dirty-change`, `saved`, `finalized`; escucha `reload`,
  `reference-created` y `lane-assignee-created`. Importar BPMN abre el drawer `urls[:import]`.
  Implementación de referencia completa en el dummy (búsquedas, drawers y streams), verificada en
  `/admin/process_flows/:id`.
- [x] F8 Notas, comparación, salidas, docs — notas de revisión numeradas con etiquetas de la app
  (`annotation_tags:`), modo comparación (`compare_with:`) superpuesto o lado a lado por id,
  descargas `.bpmn` (BPMN 2.0 XML con DI; carriles externos como participantes; validado con
  Nokogiri), PNG y SVG del diagrama completo con título y marca de agua (`watermark:`), imprimir.
  `docs/api/bpmn-editor.md`, sección en `docs/guides/components.md`, fila en el README, entrada en
  el CHANGELOG. Pruebas de documento grande (60 actividades: layout, ruteo y reglas) en JS, Ruby y
  preview `large`; Cypress `cypress/e2e/bpmn-editor.cy.js` (6 pruebas en verde).

## BPMN-L · Acomodo automático y calidad del layout

**Avance BPMN-L: 100 %.** Commits `bf30767c` (métrica, pruebas por propiedades, router y acomodo
incremental), `dfc6055e` (Autoajustar completo) y `cf9b5f3e` (integración en el editor), más el
de documentación.

### Qué hay

- **Métrica** `model/layoutQuality.js`: violaciones duras (encimados, fuera de carril o en el
  encabezado, línea por elemento/nombre/insignia, tramos compartidos, etiquetas encimadas,
  insignia sobre etiqueta) y blandas (cruces, quiebres, desvío del camino feliz). La usan las
  pruebas y sirve para medir en el navegador (el documento del `PUT`).
- **Router** `model/router.js`: A* sobre una rejilla ortogonal dispersa con ocupación de tramos
  (prohíbe colinealidad, penaliza cruces y quiebres), puertos repartidos por lado, reserva previa
  de todos los stubs, reintento por otros lados. Saltos de línea en cruces (`findJumps`).
- **Acomodo incremental** `model/arrange.js`: huellas (forma ∪ nombre ∪ insignia), empuje hacia
  adelante en el flujo, carriles ajustados al contenido, rejilla de 10 px por centros, `makeRoom`
  cuando una ruta no cabe. Idempotente: un paso de deshacer.
- **Autoajustar** `model/layout.js`: columnas por camino más largo, camino feliz recto, ramas de
  splits simétricas, excepciones alternadas, artefactos junto a su elemento; encuadre con zoom
  mínimo de 40 % y, si no cabe, desde el inicio.
- **Etiquetas** `model/labels.js` y `model/edgeLabels.js`: eventos abajo, gateways arriba,
  conexiones junto a su origen; la misma geometría en lienzo, exportación y métrica.
- **UI:** interruptor «Ajuste automático», ayuda en un pie fijo (ya no tapa «Selección múltiple»),
  Leyenda y «Por colocar» plegables y fuera del área de encuadre, preview editable que arranca del
  ejemplo limpio (`fresh`).

### Métrica antes y después (violaciones duras)

| Flujo de referencia | Antes (al cargar) | Después (Autoajustar, H/V) | Cruces | Quiebres prom./máx. |
|---|---|---|---|---|
| Factura | 3 | 0 / 0 | 0 | 0.13 / 1 |
| Decisión con retrabajo | 1 | 0 / 0 | 1 | 1 / 4 |
| Paralelo de 3 ramas | 6 | 0 / 0 | 0 | 0.67–0.89 / 2 |
| 60 actividades | 9 | 0 / 0 | 0 | 0.37 / 2 |
| Dos participantes externos | 1 | 0 / 0 | 0 | 0.67 / 2 |

Desvío del camino feliz: 0 en todos. Pruebas por propiedades: 200 secuencias × 30 operaciones con
semillas fijas, 0 violaciones duras (reportan la secuencia mínima si fallan).

**En el navegador** (Playwright contra el dummy, capturas fuera del repo): el gateway Sí/No del
ejemplo sale limpio; un flujo de 12 elementos armado sólo con el menú rápido y la paleta queda con
0 duras, 2 cruces y 1.06 quiebres promedio, y tras «Autoajustar» con 0 duras, 0 cruces y 0.56.

### Verificación independiente (team-lead) y arreglos

- **Ramas de gateway por el mismo lado** (Sí y No bajaban paralelas por el vértice inferior):
  nueva restricción dura `gatewaySharedSide` en `layoutQuality` para gateways con ≤ 3 salidas,
  cubierta por las pruebas por propiedades y los fixtures. El router asigna lados distintos: la
  continuación en el carril del gateway (o, sin ella, la rama más alineada) sale recta por el
  lado de lectura; las demás, hacia su destino; un reintento de ruta no toma el lado de una rama
  hermana.
- **Camino recto desde el gateway:** «Autoajustar» cuenta las filas por carril, así que la
  continuación en el mismo carril conserva la fila aunque el camino más largo cambie de carril
  (en la factura, «No» → Fin queda en línea recta y «Sí» baja a Tesorería). No existe en el
  contrato una marca de «rama principal»; no se agregó.
- **Leyenda sobre el contenido:** se pliega sola cuando la vista se asienta con un elemento
  debajo (opción elegida en lugar de reservar una franja del lienzo, que restaría ~290 px al
  diagrama siempre). El encuadre deja libre además el panel de propiedades.
- **Menú rápido hacia abajo desde el último carril:** con carriles ajustados al contenido no
  quedaba banda libre y se rechazaba; ahora crece el carril del borde.

Flujo de 12 elementos en el navegador (menú rápido y paleta): 0 duras, 1 cruce, 0.5 quiebres
promedio; tras «Autoajustar», 0 duras, 1 cruce, 0.67.

### Lo que no se logró

- Las líneas no se animan durante el acomodo (los nodos sí, 0.22 s); se rerutean al terminar.
- Los saltos de línea se dibujan sobre los tramos horizontales.
- El acomodo incremental empuja hacia adelante, no compacta: tras borrar puede quedar un hueco
  hasta «Autoajustar».
- El retrabajo conserva un cruce y un máximo de 4 quiebres (el lazo por debajo del flujo).
- Un gateway con tres ramas, dos de ellas hacia abajo, saca una por arriba y la rodea: lados
  distintos, pero con más quiebres.

### Decisiones

- Sin librerías de layout (ELK, dagre): el contrato «a lo largo del flujo, dentro del carril» es
  propio y las pruebas fijan el resultado.
- Durante el arrastre se usa el ruteo rápido; el router completo corre al soltar.
- `newId` determinista para poder reproducir secuencias en las pruebas por propiedades.
- El tecleo en el panel, redimensionar carriles y mover el pool no disparan el acomodo.

## BPMN-R · Ajuste local siempre activo, ramificar y notación

### Ajuste local siempre activo

Se quitaron el interruptor «Ajuste automático» y la opción `auto_arrange:` (nunca se
publicaron). El ajuste local corre tras cada edición y ni el usuario ni la app lo apagan;
«Autoajustar» queda como la acción global. Al borrar, el tramo del flujo que queda vacío en
todos los carriles y es más ancho que una columna se cierra: lo que sigue se recorre hacia
atrás, todos los carriles juntos, y nada de lo que está antes del hueco se mueve. La métrica
cuenta `emptyStretches`, y las pruebas por propiedades fallan si un borrado deja un hueco así.
El bloqueo por encimado (R18) dejó de usarse: el ajuste recorre en vez de rechazar; R18 sigue
como pendiente si los datos de la app traen un encimado.

### Ramificar

Caso del usuario: «Registrar pago» con una salida hacia arriba y otra pedida a la derecha. El
menú rápido ya no falla: ofrece «Bifurcar con: Decisión (exclusivo) · Paralelo» (e Inclusivo si
la paleta lo trae), inserta el gateway tras la actividad, pasa la salida existente por él y pone
el elemento nuevo como segunda rama, en un solo paso de deshacer; las ramas quedan sin nombre
(R03 pendiente). Si la salida ya va a un gateway de apertura, el elemento es otra rama de ése.
Una dirección imposible se deshabilita con el motivo en el tooltip. Al conectar a mano el
bloqueo sigue y el aviso ofrece «Agregar gateway».

### Auditoría de figuras

Todas las figuras salen de `shapes.jsx` (`NodeShape`): el lienzo, la paleta, el menú rápido,
«Más…», la leyenda y la exportación. El ícono es la misma figura en una caja de 28 px (4:3 para
actividades y grupos), con el radio y los marcadores proporcionales a la altura. La preview
`catalog` dibuja cada elemento como lo dibuja su ícono y como lo dibuja el lienzo, con su
nombre debajo.

| Elemento | Notación esperada | Estado | Referencia (OMG BPMN 2.0.2, cap. de notación) |
|---|---|---|---|
| Tarea (task) | rectángulo redondeado, radio 10 % de la altura | corregido (el ícono salía como píldora: rx 9 en 20 px) | Activities › Task |
| Tareas de usuario, servicio, envío, recepción, script, regla de negocio, manual | rectángulo redondeado con el marcador de tipo arriba a la izquierda; envío relleno, recepción hueco | corregido (forma del ícono; el marcador escala con la altura, con piso legible) | Activities › Task types (markers) |
| Subproceso colapsado | rectángulo redondeado, [+] pequeño abajo al centro; el mismo violeta en paleta, lienzo y leyenda | corregido ([+] centrado y grande en el ícono; rosa en vez del morado del diseño) | Activities › Sub-Process (collapsed marker) |
| Gateway exclusivo, paralelo, inclusivo, complejo | rombo con X, +, círculo grueso y asterisco | correcto | Gateways |
| Gateway basado en eventos | rombo, doble círculo y pentágono | correcto | Gateways › Event-Based Gateway |
| Basado en eventos de inicio | rombo, círculo sencillo y pentágono | correcto | Gateways › Event-Based Gateway (instantiate) |
| Paralelo basado en eventos | rombo, círculo sencillo y cruz hueca | corregido (salía con doble círculo y una cruz de trazo) | Gateways › Event-Based Gateway (parallel) |
| Eventos de inicio (vacío, tiempo, mensaje, condicional, señal, múltiple, paralelo múltiple) | círculo de trazo delgado, glifo de captura hueco | correcto | Events › Start Event |
| Eventos intermedios de captura y de lanzamiento | doble trazo; captura hueca, lanzamiento relleno | correcto | Events › Intermediate Event |
| Eventos de fin (todos) | trazo grueso, glifo relleno | correcto | Events › End Event |
| Anotación de texto | corchete abierto | correcto | Artifacts › Text Annotation |
| Grupo | rectángulo redondeado, trazo raya-punto | corregido (el ícono salía como círculo punteado) | Artifacts › Group |
| Objeto de datos, colección, entrada, salida | hoja con esquina doblada; tres barras; flecha hueca; flecha rellena | correcto | Items and Data › Data Object, Data Input/Output |
| Almacén de datos | cilindro | correcto | Items and Data › Data Store |
| Flujo de secuencia | línea continua, punta rellena | correcto | Connecting Objects › Sequence Flow |
| Flujo de mensaje | línea discontinua, círculo hueco en el origen, punta hueca | correcto | Collaboration › Message Flow |
| Asociación | línea punteada | correcto | Artifacts › Association |

## BPMN-X · Cobertura de criterios AFAL

Los 104 criterios de la matriz «Criterios BPMN Rev.01». **Regla**: el editor la revisa
(el id de la regla es el código del criterio que la nombra; `criteria` lista los que
cubre). **Función del componente**: el editor lo hace por construcción. **Configuración de
la app**: depende de lo que la app pase. **Revisión humana**: es de criterio, ningún
chequeo lo decide. Las reglas que la matriz basa en BPMN 2.0 están activas por omisión;
las que son solo lineamiento AFAL (`afal`) se activan con `rules: { enabled: %w[afal] }`.
Las reglas de redacción son advertencias.

Reglas nuevas: COM-19, COM-20, COM-12, COM-02, DEC-03, EST-05, EST-01, VIS-10, EVI-03,
EVI-05 (activas) y COM-22, EVF-04, SUB-05, ACT-02, ACT-07, ACT-09, ACT-03, ACT-10, LAN-08
(`afal`). Cambian: R05 (COM-21), R08 (ya no pide descripción: EVM-04/06), R21 (LAN-09),
B11 (verbo al inicio; rombo azul e inclusivo), y R12, R16 y B11 se activan por omisión.
`test/javascript/bpmn_editor/criteria.test.js` reproduce los ejemplos «Uso incorrecto /
Uso correcto» de cada criterio que revisa una regla.

| Código | Cobertura | Cómo |
|---|---|---|
| LAN-01 | Función del componente | carriles del pool; R26 (todo elemento dentro de un carril) |
| LAN-02 | Regla + Revisión humana | R22 (nombre específico); si es puesto, rol o función lo decide el área |
| LAN-03 | Revisión humana + Configuración de la app | denominación oficial; la app liga el responsable del carril (`urls[:lane_assignees]`) |
| LAN-04 | Revisión humana | participante genérico |
| LAN-05 | Revisión humana | función como participante |
| LAN-06 | Regla + Revisión humana | R26 (dentro de un carril); quién ejecuta realmente, el área |
| LAN-07 | Regla | R10 |
| LAN-08 | Regla | LAN-08 (`afal`, advertencia) |
| LAN-09 | Regla | R21, que ahora cuenta carriles con actividades |
| LAN-10 | Configuración de la app | opción de orientación fija (otra parte de BPMN-X) |
| EXT-01 | Función del componente | carril externo gris (`kind: external`) |
| EXT-02 | Función del componente | actividad externa blanca |
| EXT-03 | Función del componente | actividad interna azul |
| ACT-01 | Regla + Revisión humana | ACT-07 (solo recibe o envía); si hay transformación, el área |
| ACT-02 | Regla | ACT-02 (`afal`, advertencia); R17 sigue opcional |
| ACT-03 | Regla | ACT-03 «vague» (`afal`, advertencia); R23 |
| ACT-04 | Regla | ACT-03 «operative» |
| ACT-05 | Regla | ACT-03 «several» |
| ACT-06 | Regla | R16, ahora activa por omisión |
| ACT-07 | Regla | ACT-07 |
| ACT-08 | Regla | ACT-07 |
| ACT-09 | Regla | ACT-09 (`afal`, advertencia) |
| ACT-10 | Regla | ACT-10 (`afal`, advertencia) |
| ACT-11 | Regla | ACT-10 |
| ACT-12 | Regla | ACT-10 |
| ACT-13 | Regla | COM-22 (`afal`) |
| EVI-01 | Regla | R12, ahora activa por omisión |
| EVI-02 | Regla | R06 |
| EVI-03 | Regla | EVI-03 (advertencia) |
| EVI-04 | Revisión humana | que el tipo corresponda al detonante; EVI-05 cubre el caso temporal |
| EVI-05 | Regla | EVI-05 (advertencia) |
| EVI-06 | Regla | R24 |
| EVM-01 | Regla + Configuración de la app | VIS-10 con la paleta que la app configura (`palette:` sin los otros eventos) |
| EVM-02 | Revisión humana | acontecimiento, no trabajo |
| EVM-03 | Revisión humana | comunicación real |
| EVM-04 | Regla | R08 (nombre genérico «Mensaje») |
| EVM-05 | Revisión humana | espera temporal |
| EVM-06 | Regla | R08 (nombre genérico «Tiempo») |
| EVM-07 | Revisión humana | espera frente a fecha límite |
| EVM-08 | Revisión humana | espera condicionada |
| EVM-09 | Regla | EVI-03 (evento condicional) |
| EVF-01 | Regla | EST-01, R13 y R12 |
| EVF-02 | Regla | R07 |
| EVF-03 | Regla | EVI-03 (evento de fin) |
| EVF-04 | Regla | EVF-04 (`afal`) |
| EVF-05 | Regla | R24 |
| COM-01 | Regla + Función del componente | R01/R02; «Bifurcar con» y «Agregar gateway» |
| COM-02 | Regla + Función del componente | COM-02; rombo azul (decisión Sí/No) |
| COM-03 | Función del componente + Revisión humana | XOR con X; que solo una alternativa aplique, el área |
| COM-04 | Revisión humana | naturaleza inclusiva |
| COM-05 | Revisión humana | paralelismo obligatorio |
| COM-06 | Regla | R09 (nombre) y B11 (pregunta) |
| COM-07 | Regla | R03 y COM-02 |
| COM-08 | Regla | R09 y B11: el criterio es el nombre o la pregunta, sin campo extra |
| COM-09 | Regla | R03 |
| COM-10 | Revisión humana | exclusividad de las condiciones |
| COM-11 | Revisión humana | inclusividad de las condiciones |
| COM-12 | Regla | COM-12 |
| COM-13 | Regla | B11 (verbo al inicio), activa por omisión |
| COM-14 | Regla | R01 |
| COM-15 | Regla | COM-19 |
| COM-16 | Regla | COM-19 |
| COM-17 | Regla | COM-19; R05 |
| COM-18 | Regla | COM-19; R05 |
| COM-19 | Regla | COM-19 |
| COM-20 | Regla | COM-20 |
| COM-21 | Regla | R05 ya no exige cierre a rutas que terminan |
| COM-22 | Regla + Función del componente | COM-22 (`afal`); conectar hacia atrás ofrece el XOR de unión |
| DEC-01 | Regla | R09 y B11 |
| DEC-02 | Regla | R03 |
| DEC-03 | Regla | DEC-03 (advertencia) |
| SEC-01 | Revisión humana | orden real de ejecución |
| SEC-02 | Regla + Función del componente | R13, R25; el editor no deja conexiones sin destino |
| SEC-03 | Función del componente | toda conexión dibuja su flecha |
| SEC-04 | Regla | EST-01 |
| SEC-05 | Regla | R01 |
| SUB-01 | Función del componente + Regla | token de color del procedimiento relacionado, gris por omisión; R11 |
| SUB-02 | Función del componente | nombre sincronizado con `reference.label` |
| SUB-03 | Revisión humana | dependencia de resultado |
| SUB-04 | Función del componente | el procedimiento relacionado se dibuja colapsado; no hay subprocesos expandidos |
| SUB-05 | Regla | SUB-05 (`afal`) |
| SUB-06 | Regla | SUB-05 |
| SUB-07 | Regla | SUB-05 |
| SUB-08 | Revisión humana | salida habilitante |
| SUB-09 | Regla | R01 (la caja + es una actividad) |
| ART-01 | Revisión humana + Regla | uso complementario; B03/B04 impiden que una anotación entre al flujo |
| ART-02 | Revisión humana | la lógica no va en notas |
| EST-01 | Regla | EST-01 |
| EST-02 | Regla | EST-01 |
| EST-03 | Revisión humana | orden lógico de las actividades |
| EST-04 | Regla | COM-22 |
| EST-05 | Regla | EST-05 |
| EST-06 | Función del componente + Revisión humana | caja gris (+); el alcance, el área |
| VIS-01 | Función del componente | acomodo compacto + indicador VIS-02 (otra parte de BPMN-X) |
| VIS-02 | Función del componente | acomodo compacto + indicador VIS-02 (otra parte de BPMN-X) |
| VIS-03 | Función del componente | acomodo compacto + indicador VIS-02 (otra parte de BPMN-X) |
| VIS-04 | Función del componente | «Autoajustar»: columnas alineadas y rejilla de 10 px |
| VIS-05 | Función del componente | ajuste local y métrica `layoutQuality` (sin encimados) |
| VIS-06 | Función del componente | ruteo con cruces mínimos y saltos de línea |
| VIS-07 | Regla + Función del componente | R18; la métrica mantiene en cero etiquetas sobre líneas o nodos |
| VIS-08 | Función del componente | acomodo compacto + indicador VIS-02 (otra parte de BPMN-X) |
| VIS-09 | Función del componente | interna azul, externa blanca en carril gris, procedimiento relacionado gris (token) |
| VIS-10 | Regla | VIS-10 |
| VIS-11 | Función del componente | etiquetas junto a su ruta (`edgeLabels`); la métrica las mantiene sin encimar |

Conteo (un criterio puede tener dos coberturas): Configuración de la app 3, Función del componente 24, Regla 67, Revisión humana 24.

## Pendiente y siguiente paso

- **Importar BPMN en el cliente:** no se hizo; el botón abre el drawer de la app (`urls[:import]`)
  y la app responde `bali_bpmn_reload`. Si se quiere en el cliente, el siguiente paso es un
  `fromBpmnXml` con `DOMParser` en `model/bpmnXml.js` (el inverso de `toBpmnXml`).
- **Rutas manuales (waypoints):** se dibujan y se exportan si vienen en el documento, pero no hay
  manijas para editarlas en el lienzo; se puede fijar el puerto o recalcular.
- **Bordes intermedios (boundary events), subprocesos expandidos y pools múltiples internos:** no
  están en el modelo; se conservan como tipos desconocidos.
- **`openDrawerUrl`** está copiado de `GanttFlow.jsx` en `bpmn_editor/drawer.js`; extraerlo a un
  util compartido es un cambio aparte que toca el Gantt.
- **Revisión independiente:** hecha (agente general, sólo lectura) y aplicada: 14 hallazgos, todos
  corregidos — finalizar fallido que dejaba la versión atrás (el 422 trae `version`), cambios
  pendientes al navegar con Turbo, guardar y finalizar serializados, respuestas viejas ignoradas
  tras una recarga, insertar sobre una conexión sin inicio/fin y conservando el id, waypoints al
  borrar carril, alinear sin entrar al encabezado, XML con ids únicos y orden del XSD, `Data` sin
  500 ante tipos inválidos, pendientes del servidor de elementos borrados, atajos en modo Navegar,
  `registerBpmnEditor` instala la acción de stream, `forSave` sin `stencil`. Falta, antes del PR, la
  pasada con `dhh-code-reviewer` que pide `.claude/CLAUDE.md`.
