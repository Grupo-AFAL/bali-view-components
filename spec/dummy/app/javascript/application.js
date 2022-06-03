// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  DropdownController,
  HelpTipController,
  HovercardController,
  TabsController,
  TreeViewItemController,
  ChartController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('dropdown', DropdownController)
application.register('help-tip', HelpTipController)
application.register('hovercard', HovercardController)
application.register('tabs', TabsController)
application.register('tree-view-item', TreeViewItemController)
application.register('chart', ChartController)
