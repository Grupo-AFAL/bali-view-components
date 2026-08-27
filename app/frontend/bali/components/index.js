/**
 * Bali Component Controllers - Core Bundle
 *
 * These controllers are bundled with ViewComponents and provide
 * interactivity for the component templates.
 *
 * Usage:
 *   import { ModalController } from 'bali-view-components'
 *   application.register('modal', ModalController)
 *
 * Heavy/Optional modules (import separately):
 *   - Charts:           import { ChartController } from 'bali-view-components/charts'
 *   - Block Editor:     import { BlockEditorController } from 'bali-view-components/block-editor'
 *   - Rich Text Editor: import { RichTextEditorController } from 'bali-view-components/rich-text-editor'
 */

import { installConfirmDialog } from '../../../assets/javascripts/bali/confirm/confirm_dialog'
import { AppLayoutController } from '../../../components/bali/app_layout/index'
import { ModalController } from '../../../components/bali/modal/index'
import { DrawerController } from '../../../components/bali/drawer/index'
import { DropdownController } from '../../../components/bali/dropdown/index'
import { TabsController } from '../../../components/bali/tabs/index'
import { NavbarController } from '../../../components/bali/navbar/index'
import { SideMenuController } from '../../../components/bali/side_menu/index'
import { SideMenuFlyoutController } from '../../../components/bali/side_menu/flyout/index'
import { SideMenuTriggerController } from '../../../components/bali/side_menu/trigger/index'
import { AvatarController } from '../../../components/bali/avatar/index'
import { TimeagoController } from '../../../components/bali/timeago/index'
import { RateController } from '../../../components/bali/rate/index'
import { BulkActionsController } from '../../../components/bali/bulk_actions/index'
import { CarouselController } from '../../../components/bali/carousel/index'
import { ChatController } from '../../../components/bali/chat/index'
import { ClipboardController } from '../../../components/bali/clipboard/index'
import { HovercardController } from '../../../components/bali/hover_card/index'
import { KanbanController } from '../../../components/bali/kanban/index'
import { WidgetGridController, WidgetGridEditModeController } from '../../../components/bali/widget_grid/index'
import { RevealController } from '../../../components/bali/reveal/index'
import { SortableListController } from '../../../components/bali/sortable_list/index'
import { TooltipController } from '../../../components/bali/tooltip/index'
import { ImageFieldController } from '../../../components/bali/image_field/index'
import { ImageExpanderController } from '../../../components/bali/image_grid/index'
import { DirectUploadController } from '../../../components/bali/direct_upload/index'
import { RecurrentEventRuleController } from '../../../components/bali/recurrent_event_rule_form/index'
import { AlertController } from '../../../components/bali/alert/index'
import { LocationsMapController } from '../../../components/bali/locations_map/index'
import {
  FiltersController,
  FilterGroupController,
  ConditionController,
  AppliedTagsController,
  MultiSelectController
} from '../../../components/bali/filters/index'
import {
  ColumnSelectorController,
  SavedViewsController,
  ToolbarOverflowController,
  ExportLinksController
} from '../../../components/bali/data_table/index'
import { DocumentEditorController } from '../../../components/bali/document_editor/index'
import { DocumentPageController } from '../../../components/bali/document_page/index'
import { TreeViewItemController } from '../../../components/bali/tree_view/item/index'
import { FeedbackWidgetController } from '../../../components/bali/feedback_widget/index'
import { CommandController } from '../../../components/bali/command/index'
import { StatusController } from '../../../components/bali/status/index'
import { QrScannerController } from '../../../components/bali/qr_scanner/index'
import { ToastContainerController } from '../../../components/bali/toast_container/index'
import { SplitViewController } from '../../../components/bali/split_view/index'
import { SplitViewListController } from '../../../components/bali/split_view/list/index'

export {
  AlertController,
  AppLayoutController,
  AppliedTagsController,
  AvatarController,
  BulkActionsController,
  CarouselController,
  ChatController,
  ClipboardController,
  ColumnSelectorController,
  CommandController,
  ConditionController,
  DirectUploadController,
  DocumentEditorController,
  DocumentPageController,
  DrawerController,
  DropdownController,
  ExportLinksController,
  FeedbackWidgetController,
  FilterGroupController,
  FiltersController,
  HovercardController,
  ImageExpanderController,
  ImageFieldController,
  KanbanController,
  LocationsMapController,
  ModalController,
  MultiSelectController,
  NavbarController,
  QrScannerController,
  RateController,
  RecurrentEventRuleController,
  RevealController,
  SavedViewsController,
  SideMenuController,
  SideMenuFlyoutController,
  SideMenuTriggerController,
  SortableListController,
  SplitViewController,
  SplitViewListController,
  StatusController,
  TabsController,
  TimeagoController,
  ToastContainerController,
  ToolbarOverflowController,
  TooltipController,
  TreeViewItemController,
  WidgetGridController,
  WidgetGridEditModeController
}

/**
 * THE manifest of core component controllers: Stimulus identifier -> controller class.
 *
 * registerAll derives from this map; the named exports above exist so an app can
 * import one controller without pulling in the rest. scripts/check-controller-manifest.mjs
 * keeps the two lists and the source tree in sync.
 *
 * ChartController, BlockEditorController and RichTextEditorController are
 * deliberately absent: they drag in Chart.js, React/BlockNote and TipTap
 * respectively, so they ship from the ./charts, ./block-editor and
 * ./rich-text-editor entries instead.
 *
 * The @__PURE__ annotation lets bundlers drop the map (and with it every import
 * above) when a consumer only imports a single named controller.
 */
export const CONTROLLERS = /* @__PURE__ */ Object.freeze({
  // Core
  'app-layout': AppLayoutController,
  modal: ModalController,
  drawer: DrawerController,
  dropdown: DropdownController,
  tabs: TabsController,
  navbar: NavbarController,
  'side-menu': SideMenuController,
  'side-menu-flyout': SideMenuFlyoutController,
  'side-menu-trigger': SideMenuTriggerController,

  // Data display
  avatar: AvatarController,
  timeago: TimeagoController,
  rate: RateController,

  // Interactive
  'bulk-actions': BulkActionsController,
  carousel: CarouselController,
  chat: ChatController,
  clipboard: ClipboardController,
  hovercard: HovercardController,
  kanban: KanbanController,
  reveal: RevealController,
  'bali-widget-grid': WidgetGridController,
  'bali-widget-grid-edit-mode': WidgetGridEditModeController,
  'sortable-list': SortableListController,
  tooltip: TooltipController,
  status: StatusController,
  'qr-scanner': QrScannerController,

  // Form
  'image-field': ImageFieldController,
  'image-expander': ImageExpanderController,
  'direct-upload': DirectUploadController,
  'recurrent-event-rule': RecurrentEventRuleController,

  // Feedback
  alert: AlertController,
  'toast-container': ToastContainerController,

  // Map
  'locations-map': LocationsMapController,

  // Filters
  filters: FiltersController,
  'filter-group': FilterGroupController,
  condition: ConditionController,
  'applied-tags': AppliedTagsController,
  'multi-select': MultiSelectController,

  // DataTable
  'column-selector': ColumnSelectorController,
  'saved-views': SavedViewsController,
  'toolbar-overflow': ToolbarOverflowController,
  'export-links': ExportLinksController,

  // Document
  'document-editor': DocumentEditorController,
  'document-page': DocumentPageController,

  // Navigation
  'tree-view-item': TreeViewItemController,

  // Integration
  'feedback-widget': FeedbackWidgetController,

  // Command palette
  command: CommandController,

  // Master-detail
  'split-view': SplitViewController,
  'split-view-list': SplitViewListController
})

/**
 * Register all core Bali component controllers with a Stimulus application
 *
 * NOTE: Heavy/optional modules are NOT included. Import them separately:
 *   - Charts:           import { registerCharts } from 'bali-view-components/charts'
 *   - Block Editor:     import { registerBlockEditor } from 'bali-view-components/block-editor'
 *   - Rich Text Editor: import { registerRichTextEditor } from 'bali-view-components/rich-text-editor'
 *
 * @param {Application} application - Stimulus application instance
 */
export function registerAll (application) {
  // Replace Turbo's native window.confirm with Bali's styled dialog (idempotent)
  installConfirmDialog()

  for (const [identifier, controller] of Object.entries(CONTROLLERS)) {
    application.register(identifier, controller)
  }
}
