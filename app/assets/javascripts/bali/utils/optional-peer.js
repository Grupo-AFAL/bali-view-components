/**
 * A `.catch()` handler for the dynamic `import()` of an optional peer dependency.
 *
 * The `.catch()` is not decoration — it is the thing that keeps a host's build
 * working. esbuild resolves `import()` at BUNDLE time like any other import and
 * fails the whole build on a specifier it cannot find, dynamic or not, UNLESS the
 * call carries a `.catch()`. Its own error says so: "You can also add `.catch()`
 * here to handle this failure at run-time instead of bundle-time."
 *
 * Measured on an app that had installed exactly the three peers every guide called
 * required and then wired the documented `registerAll` + `registerCharts`: 22
 * `Could not resolve` errors across 12 packages, and no bundle. Nine of them came
 * from `import()` calls that the same guides described as safe to skip.
 *
 * With the guard, a missing package rejects in the browser instead: this handler
 * names it, returns null, and the controller returns early — the behaviour
 * docs/guides/installation.md Step 6 has always promised. Nothing changes for a
 * host that installed the package; the promise never rejects.
 *
 * IT DISTINGUISHES "NOT INSTALLED" FROM "INSTALLED AND BROKEN", because the advice
 * is opposite and the second one is not this library's business. Measured in
 * Chromium on an esbuild bundle: an absent package rejects with
 * `TypeError: Failed to resolve module specifier 'pkg'` — esbuild leaves the bare
 * specifier in the output and the browser cannot resolve it — while a package that
 * is present and throws while evaluating rejects with its own error, verbatim.
 * Telling the second host to `yarn add` something they already have sends them
 * chasing an installation that is not the problem.
 *
 * WHY A `.catch()` HANDLER AND NOT AN `importOptional('tippy.js')` THAT RETURNS
 * THE MODULE OR NULL — which would be the nicer API, and cannot work. A loader
 * like that receives the package name as a VARIABLE, and esbuild only bundles an
 * `import()` whose specifier is a literal at the call site. Measured on the same
 * fixture, one package (date-fns), two shapes: through a helper the output is
 * 236 bytes with zero references to the package — it is not in the bundle at all,
 * so a host that DID install it gets a bare specifier the browser cannot resolve;
 * written as `import('date-fns').catch(...)` the output is 241 KB with 608
 * references. The three-line dance at each call site is what keeps the specifier
 * where the bundler can see it.
 *
 * Always null-check BEFORE destructuring, or a missing package turns into a
 * TypeError with none of the above in it:
 *
 *   const mod = await import('tippy.js').catch(optionalPeer('tippy.js'))
 *   if (!mod) return
 *   const { default: tippy } = mod
 *
 * @param {string} packageName - the npm package, spelled as in package.json
 * @returns {(error: Error) => null}
 */

// The shapes a module-resolution failure takes. The first is what Chromium
// produces for a bundled-but-unresolved bare specifier (measured); the rest are
// the same failure in Firefox, Safari and in a server-side/bundler context, kept
// so the message stays right away from the browser this was measured in.
const NOT_INSTALLED = /failed to resolve module specifier|failed to fetch dynamically imported module|error loading dynamically imported module|bare specifier|importing a module script failed|cannot find module/i

export function optionalPeer (packageName) {
  return error => {
    if (NOT_INSTALLED.test(String(error && error.message))) {
      console.error(
        `[bali] needs the \`${packageName}\` npm package, which bali-view-components lists as an ` +
          `optional peer and does not bundle. Run \`yarn add ${packageName}\` and rebuild. ` +
          'See docs/guides/installation.md, Step 6.',
        error
      )
    } else {
      console.error(
        `[bali] the \`${packageName}\` npm package IS installed but failed while loading, so the ` +
          'component that needs it stayed off. This is not a missing dependency — `yarn add` ' +
          'will not help. The error it threw:',
        error
      )
    }

    return null
  }
}
