// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  HelpTipController,
  TabsController,
  TreeViewItemController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('help-tip', HelpTipController)
application.register('tabs', TabsController)
application.register('tree-view-item', TreeViewItemController)
