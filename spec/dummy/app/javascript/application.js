// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  ChartController,
  DropdownController,
  FilterFormController,
  HelpTipController,
  HovercardController,
  NavbarController,
  NotificationController,
  PopupController,
  TabsController,
  TreeViewItemController,
  SelectedController,
  SideMenuController,
  SortableListController,
  SubmitOnChangeController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('chart', ChartController)
application.register('dropdown', DropdownController)
application.register('filter-form', FilterFormController)
application.register('help-tip', HelpTipController)
application.register('hovercard', HovercardController)
application.register('navbar', NavbarController)
application.register('notification', NotificationController)
application.register('popup', PopupController)
application.register('tabs', TabsController)
application.register('tree-view-item', TreeViewItemController)
application.register('selected', SelectedController)
application.register('side-menu', SideMenuController)
application.register('sortable-list', SortableListController)
application.register('submit-on-change', SubmitOnChangeController)
