// A CommonJS module's exports, read from its `import()` namespace in either shape esbuild gives
// it: unsplit, the names are copied onto the namespace; split (bali-runtime's `bundleOptions()`),
// the namespace holds only `default`, which is `module.exports`. `name` is an export the module
// is known to have, which tells the two shapes apart.
export const commonJs = (namespace, name) => (namespace && name in namespace ? namespace : namespace?.default)
