/**
 * Bali Utility Functions
 *
 * Shared utilities used by Bali controllers.
 * Can also be used directly in consuming applications.
 *
 * Usage:
 *   import { toInt, toFloat, autoFocusInput } from 'bali-view-components'
 */

// DOM Helpers
export * from '../../../assets/javascripts/bali/utils/domHelpers'

// Formatters
export * from '../../../assets/javascripts/bali/utils/formatters'

// Form utilities
export * from '../../../assets/javascripts/bali/utils/form'

// Time utilities
export * from '../../../assets/javascripts/bali/utils/time'

// Top layer: keeps a popup portaled to <body> usable when it is opened from
// inside a modal <dialog>. Published rather than kept internal because a host
// that portals an overlay of its own hits exactly the same wall, and neither
// half of the fix is guessable — see docs/guides/overlays-and-the-top-layer.md.
export * from '../../../assets/javascripts/bali/utils/top-layer'

// Guard for the dynamic import of an optional peer. Published because a host
// controller that reaches for an optional package hits exactly the same wall:
// esbuild fails the BUILD on an `import()` it cannot resolve unless the call
// carries a `.catch()`.
export * from '../../../assets/javascripts/bali/utils/optional-peer'

// Stimulus mixins
export { default as useClickOutside } from '../../../assets/javascripts/bali/utils/use-click-outside'

// Google Maps loader (for maps-related components)
export { default as loadGoogleMapsApi } from '../../../assets/javascripts/bali/utils/google-maps-loader'
