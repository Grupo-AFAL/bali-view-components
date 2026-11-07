import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createRequire } from 'node:module'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { config } from '../dummy/esbuild.config.mjs'

const dummy = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../dummy')
const esbuild = createRequire(path.join(dummy, 'package.json'))('esbuild')

// Split, `import()` of a CommonJS module resolves to a namespace holding only `default`, so
// each of these reads it through `commonJs` (utils/common-js.js). A new edge here, in Bali or
// in a dependency, is code reading `undefined` off that namespace until someone checks it.
// `import('buffer/')` in @blocknote/xl-docx-exporter is missing on purpose: `bufferInterop`
// in esbuild.config.mjs hands it an ES module.
const KNOWN = [
  '../../app/assets/javascripts/bali/controllers/datepicker-controller.js -> flatpickr/dist/l10n/es.js',
  '../../app/components/bali/block_editor/index.js -> react',
  '../../app/components/bali/block_editor/index.js -> react-dom/client',
  '../../app/components/bali/bpmn_editor/index.js -> react',
  '../../app/components/bali/bpmn_editor/index.js -> react-dom/client',
  '../../app/components/bali/gantt/index.js -> react',
  '../../app/components/bali/gantt/index.js -> react-dom/client',
  'app/javascript/controllers/react_island_demo_controller.js -> react',
  'app/javascript/controllers/react_island_demo_controller.js -> react-dom/client'
]

test('dynamic imports of CommonJS modules in the dummy build are the known ones', async () => {
  const { metafile } = await esbuild.build({
    ...config,
    absWorkingDir: dummy,
    write: false,
    sourcemap: false,
    metafile: true,
    logLevel: 'silent'
  })

  const edges = Object.entries(metafile.inputs).flatMap(([importer, { imports }]) =>
    imports
      .filter(({ kind, path: target }) => kind === 'dynamic-import' && metafile.inputs[target]?.format === 'cjs')
      .map(({ original }) => `${importer} -> ${original}`)
  )

  assert.deepEqual([...new Set(edges)].sort(), KNOWN)
})
