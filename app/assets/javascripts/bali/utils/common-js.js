// A CommonJS module's named export, read from its `import()` namespace in either shape
// esbuild gives it: unsplit, the names are copied onto the namespace; split (bali-runtime's
// `bundleOptions()`), the namespace holds only `default`, which is `module.exports`.
// `react`, `react-dom/client` and flatpickr's locales are the CommonJS ones Bali imports.
export const namedExport = (namespace, name) => namespace?.[name] ?? namespace?.default?.[name]
