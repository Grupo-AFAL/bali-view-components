// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  AvatarController,
  CarouselController,
  ChartController,
  ClipboardController,
  DropdownController,
  FilterFormController,
  HovercardController,
  NavbarController,
  NotificationController,
  PopupController,
  RadioButtonsGroupController,
  RateController,
  RevealController,
  SelectedController,
  SideMenuController,
  SortableListController,
  SubmitOnChangeController,
  TabsController,
  TimeagoController,
  TooltipController,
  TreeViewItemController,
  TrixAttachmentsController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('avatar', AvatarController)
application.register('carousel', CarouselController)
application.register('chart', ChartController)
application.register('clipboard', ClipboardController)
application.register('dropdown', DropdownController)
application.register('filter-form', FilterFormController)
application.register('hovercard', HovercardController)
application.register('navbar', NavbarController)
application.register('notification', NotificationController)
application.register('popup', PopupController)
application.register('radio-buttons-group', RadioButtonsGroupController)
application.register('rate', RateController)
application.register('reveal', RevealController)
application.register('selected', SelectedController)
application.register('side-menu', SideMenuController)
application.register('sortable-list', SortableListController)
application.register('submit-on-change', SubmitOnChangeController)
application.register('tabs', TabsController)
application.register('timeago', TimeagoController)
application.register('tooltip', TooltipController)
application.register('tree-view-item', TreeViewItemController)
application.register('trix-attachments', TrixAttachmentsController)
