import { ModalController } from 'bali/modal'

export class DrawerController extends ModalController {
  async connect () {
    this.setupListeners('openDrawer')
  }

  disconnect () {
    this.removeListeners('openDrawer')
  }
}
