// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  ChartController,
  DropdownController,
  FilterFormController,
  HelpTipController,
  HovercardController,
  PopupController,
  TabsController,
  TreeViewItemController,
  SelectedController,
  SubmitOnChangeController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('chart', ChartController)
application.register('dropdown', DropdownController)
application.register('filter-form', FilterFormController)
application.register('help-tip', HelpTipController)
application.register('hovercard', HovercardController)
application.register('popup', PopupController)
application.register('tabs', TabsController)
application.register('tree-view-item', TreeViewItemController)
application.register('selected', SelectedController)
application.register('submit-on-change', SubmitOnChangeController)
