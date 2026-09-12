#!/usr/bin/env node
/**
 * Verifies that the Stimulus controller manifests stay in sync with the source tree.
 *
 * Bali's npm facade used to keep three hand-written lists per bundle (imports,
 * named exports, and a body of `application.register` calls). They drifted:
 * CommandController, FeedbackWidgetController and FilterPersistenceController were
 * registered by `registerAll` but never re-exported from the package root, so a host
 * app could not import them to register or subclass them. Nothing failed loudly.
 *
 * The bundles now derive `registerAll` from a single CONTROLLERS map. This script
 * guards the remaining seams:
 *
 *   1. every controller imported by a bundle appears in its CONTROLLERS map, and
 *      vice versa;
 *   2. no Stimulus identifier is claimed twice across the two bundles;
 *   3. every controller in a CONTROLLERS map is re-exported from the package root;
 *   4. every *Controller class in the source tree is reachable -- either through a
 *      CONTROLLERS map or through one of the optional entry points below;
 *   5. every identifier in the utility bundle's CONTROLLERS map is documented in
 *      the controllers catalog (docs/guides/controllers.md and its Lookbook
 *      mirror), so the catalog cannot silently fall behind a new controller.
 *
 * Check 4 is the one that would have caught the three lost controllers.
 *
 * Usage: node scripts/check-controller-manifest.mjs   (also `yarn check:manifest`)
 */

import { readFileSync, readdirSync } from 'node:fs'
import { dirname, join, relative, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const BUNDLES = [
  { name: 'controllers', path: 'app/frontend/bali/controllers/index.js' },
  { name: 'components', path: 'app/frontend/bali/components/index.js' }
]

const PACKAGE_ROOT_ENTRY = 'app/frontend/bali/index.js'

/**
 * Controllers that are deliberately absent from the two CONTROLLERS maps because
 * they drag in a heavy dependency (Chart.js, Sortable, React/BlockNote, TipTap).
 * They ship from their own package entry instead, and this script asserts that the
 * entry really does export them -- an allowlist that lies is worse than none.
 */
const OPTIONAL_ENTRY_CONTROLLERS = {
  BlockEditorController: 'app/frontend/bali/block-editor.js',
  ChartController: 'app/frontend/bali/charts.js',
  GanttController: 'app/frontend/bali/gantt.js',
  RichTextEditorController: 'app/frontend/bali/rich-text-editor.js'
}

/** Where check 4 looks for controller classes that nobody wired up. */
const SOURCE_ROOTS = [
  'app/assets/javascripts/bali/controllers',
  'app/components/bali'
]

const errors = []

const read = path => readFileSync(join(ROOT, path), 'utf8')

const isControllerName = name => name.endsWith('Controller') && name !== 'Controller'

/** Local binding names from a `{ a, b as c }` clause, keeping only controllers. */
const parseBindings = clause =>
  clause
    .split(',')
    .map(entry => entry.trim())
    .filter(Boolean)
    .map(entry => {
      const [, local] = entry.split(/\s+as\s+/)
      return (local ?? entry).trim()
    })
    .filter(isControllerName)

const importedControllers = source => {
  const names = new Set()
  for (const [, clause] of source.matchAll(/^import\s*\{([^}]*)\}\s*from\s*'[^']+'/gm)) {
    parseBindings(clause).forEach(name => names.add(name))
  }
  return names
}

/** Exported controller names, whether declared here or re-exported from elsewhere. */
const exportedControllers = source => {
  const names = new Set()
  for (const [, name] of source.matchAll(/export\s+(?:default\s+)?(?:class|const|function)\s+(\w+)/g)) {
    if (isControllerName(name)) names.add(name)
  }
  for (const [, clause] of source.matchAll(/export\s*\{([^}]*)\}/g)) {
    // In an export clause the name after `as` is the public one, so read it backwards.
    clause
      .split(',')
      .map(entry => entry.trim())
      .filter(Boolean)
      .map(entry => entry.split(/\s+as\s+/).pop().trim())
      .filter(isControllerName)
      .forEach(name => names.add(name))
  }
  return names
}

/** identifier -> controller name, read from the CONTROLLERS map of a bundle. */
const parseManifest = (source, bundle) => {
  const block = source.match(/export const CONTROLLERS\s*=[^{]*\{([\s\S]*?)\n\}\)/)
  if (!block) {
    errors.push(`${bundle.path}: no \`export const CONTROLLERS = Object.freeze({ ... })\` block found.`)
    return {}
  }

  const manifest = {}
  for (const line of block[1].split('\n')) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('//')) continue

    const entry = trimmed.match(/^'?([\w-]+)'?\s*:\s*(\w+),?$/)
    if (!entry) {
      errors.push(`${bundle.path}: cannot parse CONTROLLERS entry \`${trimmed}\`.`)
      continue
    }
    manifest[entry[1]] = entry[2]
  }
  return manifest
}

const jsFiles = function * (dir) {
  for (const entry of readdirSync(join(ROOT, dir), { withFileTypes: true })) {
    if (entry.name === 'node_modules') continue

    const path = `${dir}/${entry.name}`
    if (entry.isDirectory()) yield * jsFiles(path)
    else if (entry.name.endsWith('.js')) yield path
  }
}

const report = (headline, items) => {
  errors.push([headline, ...items.map(item => `  - ${item}`)].join('\n'))
}

// --- Checks 1 and 2: imports <-> CONTROLLERS, and unique identifiers ------------

const manifested = new Map() // controller name -> bundle path
const identifiers = new Map() // stimulus identifier -> bundle path

for (const bundle of BUNDLES) {
  const source = read(bundle.path)
  const manifest = parseManifest(source, bundle)
  const registered = new Set(Object.values(manifest))
  const imported = importedControllers(source)

  const missing = [...imported].filter(name => !registered.has(name))
  if (missing.length) {
    report(`${bundle.path}: imported but absent from CONTROLLERS (they will never be registered):`, missing)
  }

  const unimported = [...registered].filter(name => !imported.has(name))
  if (unimported.length) {
    report(`${bundle.path}: listed in CONTROLLERS but never imported (this file will not even parse):`, unimported)
  }

  for (const [identifier, name] of Object.entries(manifest)) {
    const claimedBy = identifiers.get(identifier)
    if (claimedBy) {
      errors.push(
        `Stimulus identifier '${identifier}' is registered by both ${claimedBy} and ${bundle.path}; ` +
        'the second registration silently wins.'
      )
    }
    identifiers.set(identifier, bundle.path)
    manifested.set(name, bundle.path)
  }
}

// --- Check 3: every manifested controller is reachable from the package root ----

const rootExports = exportedControllers(read(PACKAGE_ROOT_ENTRY))

const unexported = [...manifested.keys()].filter(name => !rootExports.has(name))
if (unexported.length) {
  report(
    `${PACKAGE_ROOT_ENTRY}: these controllers are registered by registerAll but not re-exported, ` +
    'so a host app cannot import, register or subclass them. Add them to the matching `export { ... }` block:',
    unexported.map(name => `${name} (from ${manifested.get(name)})`)
  )
}

// --- Check 4: no controller class in the source tree is left unreachable --------

const declared = new Map() // controller name -> first file that exports it

for (const root of SOURCE_ROOTS) {
  for (const path of jsFiles(root)) {
    for (const name of exportedControllers(read(path))) {
      if (!declared.has(name)) declared.set(name, path)
    }
  }
}

const orphans = [...declared.keys()].filter(
  name => !manifested.has(name) && !(name in OPTIONAL_ENTRY_CONTROLLERS)
)
if (orphans.length) {
  report(
    'These controller classes exist but no bundle registers them and no optional entry exports them. ' +
    'Add each one to a CONTROLLERS map, or to OPTIONAL_ENTRY_CONTROLLERS in this script if it ships ' +
    'from its own package entry:',
    orphans.map(name => `${name} (${declared.get(name)})`)
  )
}

const unreachableOptional = Object.entries(OPTIONAL_ENTRY_CONTROLLERS).filter(
  ([name, entry]) => !exportedControllers(read(entry)).has(name)
)
if (unreachableOptional.length) {
  report(
    'OPTIONAL_ENTRY_CONTROLLERS in this script claims these ship from their own entry, but the entry ' +
    'does not export them:',
    unreachableOptional.map(([name, entry]) => `${name} is not exported by ${entry}`)
  )
}

// --- Check 5: the utility identifiers are documented in the catalog -------------

const CATALOG_PAGES = [
  'docs/guides/controllers.md',
  'spec/dummy/app/views/lookbook/pages/02_guides/03_controllers.md.erb'
]

const utilityBundlePath = BUNDLES[0].path
const utilityIdentifiers = [...identifiers]
  .filter(([, path]) => path === utilityBundlePath)
  .map(([identifier]) => identifier)

for (const page of CATALOG_PAGES) {
  const catalog = read(page)
  const undocumented = utilityIdentifiers.filter(
    identifier => !catalog.includes(`\`${identifier}\``)
  )
  if (undocumented.length) {
    report(
      `${page}: identifiers registered by ${utilityBundlePath} but missing from the catalog. ` +
      'Document each one (backticked, with a markup example):',
      undocumented
    )
  }
}

// --- Result --------------------------------------------------------------------

if (errors.length) {
  console.error(`Controller manifest check failed (${errors.length} problem(s)):\n`)
  console.error(errors.join('\n\n'))
  console.error('')
  process.exit(1)
}

console.log(
  `Controller manifest OK: ${manifested.size} controllers registered across ` +
  `${BUNDLES.length} bundles, all re-exported from ${relative('.', PACKAGE_ROOT_ENTRY)}; ` +
  `${Object.keys(OPTIONAL_ENTRY_CONTROLLERS).length} more ship from optional entries.`
)
