import { ModalController } from '../modal'

export class DrawerController extends ModalController {
  async connect () {
    this.setupListeners('openDrawer')
  }

  disconnect () {
    this.removeListeners('openDrawer')
  }
}
