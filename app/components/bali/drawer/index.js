import { ModalController } from '../modal/index.js'

// Hardcoded instead of letting `dispatch` default to `this.identifier`, so the
// public event name stays put when a host registers this controller under a
// different identifier.
const EVENT_PREFIX = 'bali:drawer'

// Size classes matching Drawer::Component::SIZES
const SIZE_CLASSES = {
  sm: 'max-w-sm',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl',
  full: 'max-w-full'
}

const DEFAULT_SIZE = 'md'

// Everything the drawer does beyond naming its own open class, size map and
// data attributes is inherited: opening, closing, the focus trap, the
// confirm-on-close guards (flatpickr included) and `submit`. The two overlays
// used to carry near-identical copies of all of it, which is why the same bug
// had to be fixed twice.
export class DrawerController extends ModalController {
  // Splits `bali:drawer:open` off `bali:modal:open` so a page carrying both
  // overlays does not open them at once. `bali:modal:success` is deliberately
  // NOT split — see the note on `submit` in ModalController.
  get eventPrefix () {
    return EVENT_PREFIX
  }

  get openClass () {
    return 'drawer-open'
  }

  get sizeClasses () {
    return SIZE_CLASSES
  }

  get sizeAttribute () {
    return 'data-drawer-size'
  }

  get sizeOptionKey () {
    return 'drawerSize'
  }

  get idAttribute () {
    return 'data-drawer-id'
  }

  async connect () {
    this.setupListeners(`${this.eventPrefix}:open`)

    // Store the default size class from the panel
    this._defaultSizeClass = SIZE_CLASSES[DEFAULT_SIZE]
  }

  // Unlike the modal, whose panel has no width of its own, the drawer panel
  // renders with a default size class that has to come back when a sized open
  // is closed.
  _restoreDefaultSize () {
    if (this._currentSizeClass && this.hasWrapperTarget) {
      this.wrapperTarget.classList.remove(this._currentSizeClass)
      this.wrapperTarget.classList.add(this._defaultSizeClass)
      this._currentSizeClass = null
    }
  }
}
