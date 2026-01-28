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

// Stimulus mixins
export { default as useClickOutside } from '../../../assets/javascripts/bali/utils/use-click-outside'
export { default as useDispatch } from '../../../assets/javascripts/bali/utils/use-dispatch'

// Google Maps loader (for maps-related components)
export { default as loadGoogleMapsApi } from '../../../assets/javascripts/bali/utils/google-maps-loader'
