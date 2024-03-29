// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import {
  AvatarController,
  BulkActionsController,
  CarouselController,
  ChartController,
  ClipboardController,
  DatepickerController,
  DrawingMapsController,
  DropdownController,
  FileInputController,
  FilterFormController,
  FilterAttributeController,
  GanttChartController,
  GanttFoldableItemController,
  HovercardController,
  LocationsMapController,
  NavbarController,
  NotificationController,
  PopupController,
  RadioButtonsGroupController,
  RateController,
  InteractController,
  RevealController,
  RichTextEditorController,
  SelectedController,
  SideMenuController,
  SlimSelectController,
  SortableListController,
  SubmitOnChangeController,
  TabsController,
  TableController,
  TimeagoController,
  TooltipController,
  TreeViewItemController,
  TrixAttachmentsController
} from '../../../../app/javascript/bali'

const application = Application.start()

application.register('avatar', AvatarController)
application.register('bulk-actions', BulkActionsController)
application.register('carousel', CarouselController)
application.register('chart', ChartController)
application.register('clipboard', ClipboardController)
application.register('datepicker', DatepickerController)
application.register('drawing-maps', DrawingMapsController)
application.register('dropdown', DropdownController)
application.register('file-input', FileInputController)
application.register('filter-form', FilterFormController)
application.register('filter-attribute', FilterAttributeController)
application.register('gantt-chart', GanttChartController)
application.register('gantt-foldable-item', GanttFoldableItemController)
application.register('hovercard', HovercardController)
application.register('locations-map', LocationsMapController)
application.register('navbar', NavbarController)
application.register('notification', NotificationController)
application.register('popup', PopupController)
application.register('radio-buttons-group', RadioButtonsGroupController)
application.register('rate', RateController)
application.register('interact', InteractController)
application.register('reveal', RevealController)
application.register('rich-text-editor', RichTextEditorController)
application.register('selected', SelectedController)
application.register('side-menu', SideMenuController)
application.register('slim-select', SlimSelectController)
application.register('sortable-list', SortableListController)
application.register('submit-on-change', SubmitOnChangeController)
application.register('tabs', TabsController)
application.register('table', TableController)
application.register('timeago', TimeagoController)
application.register('tooltip', TooltipController)
application.register('tree-view-item', TreeViewItemController)
application.register('trix-attachments', TrixAttachmentsController)
