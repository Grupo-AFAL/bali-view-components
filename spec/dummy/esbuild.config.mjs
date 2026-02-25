import * as esbuild from "esbuild"
import path from "path"
import { fileURLToPath } from "url"

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// Bali gem is 2 levels up from spec/dummy
const baliGemPath = path.resolve(__dirname, "../..")

// Plugin: resolve bare specifiers from gem source via dummy app's node_modules.
// When Bali's JS source (at ../../app/) imports packages like '@blocknote/core/extensions',
// esbuild can't find them because the gem has no node_modules. This plugin intercepts
// those and re-resolves from the dummy app's directory instead.
const resolveGemImports = {
  name: "resolve-gem-imports",
  setup(build) {
    build.onResolve({ filter: /.*/ }, async (args) => {
      // Prevent infinite recursion
      if (args.pluginData?.resolvedFromDummy) return null

      // Only intercept bare specifiers (not relative/absolute paths)
      if (args.path.startsWith(".") || args.path.startsWith("/")) return null

      // Skip bali paths — handled by aliases
      if (args.path.startsWith("bali")) return null

      // Only intercept imports originating from gem source (not node_modules)
      if (!args.resolveDir.startsWith(baliGemPath)) return null
      if (args.resolveDir.includes("node_modules")) return null

      // Re-resolve from the dummy app directory
      const result = await build.resolve(args.path, {
        resolveDir: __dirname,
        kind: args.kind,
        pluginData: { resolvedFromDummy: true },
      })

      if (result.errors.length > 0) return null
      return result
    })
  }
}

const config = {
  entryPoints: ["app/javascript/application.js"],
  bundle: true,
  sourcemap: true,
  format: "esm",
  outdir: path.join(__dirname, "app/assets/builds"),
  publicPath: "/assets",
  target: ["es2022", "chrome100", "firefox100", "safari15"],
  jsx: "automatic",
  // Enable "style" condition for packages that export CSS via conditions
  conditions: ["style"],
  plugins: [resolveGemImports],
  alias: {
    // Bali entry points - resolve to local gem source
    "bali": path.join(baliGemPath, "app/frontend/bali"),
    "bali/charts": path.join(baliGemPath, "app/frontend/bali/charts.js"),
    "bali/gantt": path.join(baliGemPath, "app/frontend/bali/gantt.js"),
    "bali/block-editor": path.join(baliGemPath, "app/frontend/bali/block-editor.js"),
    "bali/rich-text-editor": path.join(baliGemPath, "app/frontend/bali/rich-text-editor.js"),
  },
  // flatpickr npm package is broken (missing JS files, only .d.ts).
  // The datepicker controller uses dynamic import() so it gracefully degrades at runtime.
  external: ["flatpickr", "flatpickr/*"],
  loader: {
    ".woff": "file",
    ".woff2": "file",
    ".ttf": "file",
    ".eot": "file",
  },
}

if (process.argv.includes("--watch")) {
  const ctx = await esbuild.context(config)
  await ctx.watch()
  console.log("esbuild: watching for changes...")
} else {
  await esbuild.build(config)
  console.log("esbuild: build complete")
}
