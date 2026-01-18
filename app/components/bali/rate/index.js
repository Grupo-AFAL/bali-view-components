import { Controller } from '@hotwired/stimulus'

/**
 * RateController - Legacy controller for Rate component
 *
 * This controller is no longer used by the Rate component. DaisyUI's native
 * rating component handles visual state through CSS `:checked` pseudo-class.
 *
 * Kept for backwards compatibility with consumers who may have registered it.
 *
 * @deprecated Will be removed in next major version
 */
export class RateController extends Controller {
  // No-op: DaisyUI handles rating visuals via CSS
}
