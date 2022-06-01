// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  DropdownController,
  HelpTipController,
  TabsController,
  TreeViewItemController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('help-tip', HelpTipController)
application.register('dropdown', DropdownController)
application.register('tabs', TabsController)
application.register('tree-view-item', TreeViewItemController)
