import * as esbuild from 'esbuild'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// Bali gem is 2 levels up from test/dummy
const baliGemPath = path.resolve(__dirname, '../..')

// Plugin: resolve bare specifiers from gem source via dummy app's node_modules.
// When Bali's JS source (at ../../app/) imports packages like '@blocknote/core/extensions',
// esbuild can't find them because the gem has no node_modules. This plugin intercepts
// those and re-resolves from the dummy app's directory instead.
const resolveGemImports = {
  name: 'resolve-gem-imports',
  setup (build) {
    build.onResolve({ filter: /.*/ }, async (args) => {
      // Prevent infinite recursion
      if (args.pluginData?.resolvedFromDummy) return null

      // Only intercept bare specifiers (not relative/absolute paths)
      if (args.path.startsWith('.') || args.path.startsWith('/')) return null

      // Skip bali paths — handled by aliases
      if (args.path.startsWith('bali')) return null

      // Only intercept imports originating from gem source (not node_modules)
      if (!args.resolveDir.startsWith(baliGemPath)) return null
      if (args.resolveDir.includes('node_modules')) return null

      // Re-resolve from the dummy app directory
      const result = await build.resolve(args.path, {
        resolveDir: __dirname,
        kind: args.kind,
        pluginData: { resolvedFromDummy: true }
      })

      if (result.errors.length > 0) return null
      return result
    })
  }
}

// The bundles Lookbook and Cypress load: minified (esbuild then defines
// NODE_ENV "production", React's production build) and split, so the main
// bundle stops carrying what only an island or an optional module uses.
// Measured: application.js 25.4 MB unminified and unsplit, 0.39 MB now.
// BALI_DEV_BUILD=1 builds them unminified to debug.
const devBuild = process.env.BALI_DEV_BUILD === '1'

const outdir = path.join(__dirname, 'app/assets/builds')

// The entries go to app/assets/builds, which Propshaft digests. The chunks and
// the font files go to public/esbuild, served as they are: they are already
// named by their hash, and they are 1,700 files (Shiki's themes and grammars
// among them, with their maps) that Propshaft's development sweeper would glob
// on every request — measured 65-70 ms a request with them in its load path.
const PUBLIC_PATH = '/esbuild'
const publicDir = path.join(__dirname, 'public', PUBLIC_PATH)
const STATIC_DIRS = ['chunks', 'media']

const writeOutputs = {
  name: 'write-outputs',
  setup (build) {
    build.onEnd((result) => {
      if (!result.outputFiles) return
      fs.rmSync(publicDir, { recursive: true, force: true })
      for (const file of result.outputFiles) {
        const relative = path.relative(outdir, file.path)
        const target = STATIC_DIRS.includes(relative.split(path.sep)[0]) ? path.join(publicDir, relative) : file.path
        fs.mkdirSync(path.dirname(target), { recursive: true })
        fs.writeFileSync(target, file.contents)
      }
    })
  }
}

const config = {
  // island-demo.js and gantt-island.js are dedicated React island entries:
  // the loaders in application.js inject them on demand (see
  // docs/api/react-island.md).
  entryPoints: [
    'app/javascript/application.js',
    'app/javascript/island-demo.js',
    'app/javascript/gantt-island.js',
    'app/javascript/bpmn-editor-island.js',
    // The same island plus the optional rule package: the rules gallery only.
    'app/javascript/bpmn-editor-island-with-rules.js'
  ],
  bundle: true,
  sourcemap: true,
  format: 'esm',
  minify: !devBuild,
  splitting: true,
  write: false,
  outdir,
  publicPath: PUBLIC_PATH,
  chunkNames: 'chunks/[name]-[hash]',
  assetNames: 'media/[name]-[hash]',
  target: ['es2022', 'chrome100', 'firefox100', 'safari15'],
  jsx: 'automatic',
  // Enable "style" condition for packages that export CSS via conditions
  conditions: ['style'],
  plugins: [resolveGemImports, writeOutputs],
  alias: {
    // Bali entry points - resolve to local gem source
    bali: path.join(baliGemPath, 'app/frontend/bali'),
    'bali/charts': path.join(baliGemPath, 'app/frontend/bali/charts.js'),
    'bali/block-editor': path.join(baliGemPath, 'app/frontend/bali/block-editor.js'),
    'bali/gantt': path.join(baliGemPath, 'app/frontend/bali/gantt.js'),
    'bali/gantt-entry': path.join(baliGemPath, 'app/frontend/bali/gantt-entry.js'),
    'bali/bpmn-editor-entry': path.join(baliGemPath, 'app/frontend/bali/bpmn-editor-entry.js'),
    'bali/react-island': path.join(baliGemPath, 'app/frontend/bali/react-island.js'),
    'bali/rich-text-editor': path.join(baliGemPath, 'app/frontend/bali/rich-text-editor.js'),
    // Force a single React instance — @blocknote/xl-ai bundles react 19 as a
    // direct dependency which creates a duplicate nested copy. Without these
    // aliases, hooks and context break at runtime ("invalid hook call").
    react: path.join(__dirname, 'node_modules/react'),
    'react-dom': path.join(__dirname, 'node_modules/react-dom'),
    'react/jsx-runtime': path.join(__dirname, 'node_modules/react/jsx-runtime'),
    'react/jsx-dev-runtime': path.join(__dirname, 'node_modules/react/jsx-dev-runtime'),
    // rrule's ESM build uses extensionless imports that esbuild can't resolve.
    // Force the CJS build which works fine.
    rrule: path.join(__dirname, 'node_modules/rrule/dist/es5/rrule.js')
  },
  loader: {
    // Served from public/esbuild (`publicPath` above), not through Propshaft.
    '.woff': 'file',
    '.woff2': 'file',
    '.ttf': 'file',
    '.eot': 'file'
  }
}

// Left by the builds that wrote chunks and fonts into the Propshaft load path.
for (const dir of STATIC_DIRS) fs.rmSync(path.join(outdir, dir), { recursive: true, force: true })

if (process.argv.includes('--watch')) {
  const ctx = await esbuild.context(config)
  await ctx.watch()
  console.log('esbuild: watching for changes...')
} else {
  await esbuild.build(config)
  console.log('esbuild: build complete')
}
