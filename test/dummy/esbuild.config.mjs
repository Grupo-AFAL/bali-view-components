import * as esbuild from 'esbuild'
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

// `import("buffer/")` is CommonJS, so in a split build its namespace holds only `default`:
// @blocknote/xl-docx-exporter reads `.Buffer` off it (getFonts) and Word export threw. Same
// plugin as `bundleOptions()` in bali-runtime's javascript/esbuild.js.
const BUFFER_NAMESPACE = 'bali-buffer-interop'
const bufferInterop = {
  name: 'buffer-interop',
  setup (build) {
    build.onResolve({ filter: /^buffer\/?$/ }, (args) => {
      if (args.kind !== 'dynamic-import') return null
      return { path: 'buffer', namespace: BUFFER_NAMESPACE, pluginData: { resolveDir: args.resolveDir } }
    })
    build.onLoad({ filter: /.*/, namespace: BUFFER_NAMESPACE }, (args) => ({
      contents: "import buffer from 'buffer/index.js'\n" +
        'export const { Buffer, SlowBuffer, INSPECT_MAX_BYTES, kMaxLength } = buffer\n' +
        'export default buffer\n',
      resolveDir: args.pluginData.resolveDir,
      loader: 'js'
    }))
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
  // Minifying also defines NODE_ENV "production" (React's production build).
  // application.js measured 25.4 MB unminified, 17 MB minified. BALI_DEV_BUILD=1 builds
  // unminified to debug.
  minify: process.env.BALI_DEV_BUILD !== '1',
  // The shape hosts ship through bali-runtime's `bundleOptions()`, so Lookbook tests it: a
  // split build turns `import()` of a CommonJS module into a namespace holding only
  // `default`. Propshaft serves a `-<hash>.digested` file under its own name; any other
  // chunk name it fingerprints itself, and the entry's relative import 404s.
  splitting: true,
  chunkNames: 'chunks/[name]-[hash].digested',
  outdir: path.join(__dirname, 'app/assets/builds'),
  target: ['es2022', 'chrome100', 'firefox100', 'safari15'],
  jsx: 'automatic',
  // Enable "style" condition for packages that export CSS via conditions
  conditions: ['style'],
  plugins: [resolveGemImports, bufferInterop],
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
    // As in docs/api/block-editor.md, Step 2. A `publicPath: '/assets'` above
    // would write these URLs as `/assets/…`, which Propshaft cannot resolve: 404.
    '.woff': 'file',
    '.woff2': 'file',
    '.ttf': 'file',
    '.eot': 'file'
  }
}

if (process.argv.includes('--watch')) {
  const ctx = await esbuild.context(config)
  await ctx.watch()
  console.log('esbuild: watching for changes...')
} else {
  await esbuild.build(config)
  console.log('esbuild: build complete')
}
