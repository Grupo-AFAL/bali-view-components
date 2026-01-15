/**
 * Bali Component Controllers - Core Bundle
 *
 * These controllers are bundled with ViewComponents and provide
 * interactivity for the component templates.
 *
 * Usage with Vite:
 *   import { TableController, ModalController } from 'bali/components'
 *   application.register('table', TableController)
 *
 * Heavy/Optional modules (import separately):
 *   - Charts:          import { ChartController } from 'bali/charts'
 *   - Gantt:           import { GanttChartController } from 'bali/gantt'
 *   - Rich Text Editor: import { RichTextEditorController } from 'bali/rich-text-editor'
 */

// Core components
export { TableController } from '../../../components/bali/table/index'
export { ModalController } from '../../../components/bali/modal/index'
export { DrawerController } from '../../../components/bali/drawer/index'
export { DropdownController } from '../../../components/bali/dropdown/index'
export { TabsController } from '../../../components/bali/tabs/index'
export { NavbarController } from '../../../components/bali/navbar/index'
export { SideMenuController } from '../../../components/bali/side_menu/index'

// Data display components
export { AvatarController } from '../../../components/bali/avatar/index'
export { TimeagoController } from '../../../components/bali/timeago/index'
export { RateController } from '../../../components/bali/rate/index'

// Interactive components
export { BulkActionsController } from '../../../components/bali/bulk_actions/index'
export { CarouselController } from '../../../components/bali/carousel/index'
export { ClipboardController } from '../../../components/bali/clipboard/index'
export { HovercardController } from '../../../components/bali/hover_card/index'
export { RevealController } from '../../../components/bali/reveal/index'
export { SortableListController } from '../../../components/bali/sortable_list/index'
export { TooltipController } from '../../../components/bali/tooltip/index'

// Form components
export { ImageFieldController } from '../../../components/bali/image_field/index'
export { RecurrentEventRuleController } from '../../../components/bali/recurrent_event_rule_form/index'

// Feedback components
export { NotificationController } from '../../../components/bali/notification/index'

// Map components
export { LocationsMapController } from '../../../components/bali/locations_map/index'

// Advanced Filters (multiple controllers)
export {
  AdvancedFiltersController,
  FilterGroupController,
  ConditionController,
  AppliedTagsController,
  MultiSelectController
} from '../../../components/bali/advanced_filters/index'

// Import all for registerAll (static imports)
import { TableController } from '../../../components/bali/table/index'
import { ModalController } from '../../../components/bali/modal/index'
import { DrawerController } from '../../../components/bali/drawer/index'
import { DropdownController } from '../../../components/bali/dropdown/index'
import { TabsController } from '../../../components/bali/tabs/index'
import { NavbarController } from '../../../components/bali/navbar/index'
import { SideMenuController } from '../../../components/bali/side_menu/index'
import { AvatarController } from '../../../components/bali/avatar/index'
import { TimeagoController } from '../../../components/bali/timeago/index'
import { RateController } from '../../../components/bali/rate/index'
import { BulkActionsController } from '../../../components/bali/bulk_actions/index'
import { CarouselController } from '../../../components/bali/carousel/index'
import { ClipboardController } from '../../../components/bali/clipboard/index'
import { HovercardController } from '../../../components/bali/hover_card/index'
import { RevealController } from '../../../components/bali/reveal/index'
import { SortableListController } from '../../../components/bali/sortable_list/index'
import { TooltipController } from '../../../components/bali/tooltip/index'
import { ImageFieldController } from '../../../components/bali/image_field/index'
import { RecurrentEventRuleController } from '../../../components/bali/recurrent_event_rule_form/index'
import { NotificationController } from '../../../components/bali/notification/index'
import { LocationsMapController } from '../../../components/bali/locations_map/index'
import {
  AdvancedFiltersController,
  FilterGroupController,
  ConditionController,
  AppliedTagsController,
  MultiSelectController
} from '../../../components/bali/advanced_filters/index'

/**
 * Register all core Bali component controllers with a Stimulus application
 *
 * NOTE: Heavy/optional modules are NOT included. Import them separately:
 *   - Charts:           import { registerCharts } from 'bali/charts'
 *   - Gantt:            import { registerGantt } from 'bali/gantt'
 *   - Rich Text Editor: import { registerRichTextEditor } from 'bali/rich-text-editor'
 *
 * @param {Application} application - Stimulus application instance
 */
export function registerAll (application) {
  // Core
  application.register('table', TableController)
  application.register('modal', ModalController)
  application.register('drawer', DrawerController)
  application.register('dropdown', DropdownController)
  application.register('tabs', TabsController)
  application.register('navbar', NavbarController)
  application.register('side-menu', SideMenuController)

  // Data display
  application.register('avatar', AvatarController)
  application.register('timeago', TimeagoController)
  application.register('rate', RateController)

  // Interactive
  application.register('bulk-actions', BulkActionsController)
  application.register('carousel', CarouselController)
  application.register('clipboard', ClipboardController)
  application.register('hovercard', HovercardController)
  application.register('reveal', RevealController)
  application.register('sortable-list', SortableListController)
  application.register('tooltip', TooltipController)

  // Form
  application.register('image-field', ImageFieldController)
  application.register('recurrent-event-rule', RecurrentEventRuleController)

  // Feedback
  application.register('notification', NotificationController)

  // Map
  application.register('locations-map', LocationsMapController)

  // Advanced Filters
  application.register('advanced-filters', AdvancedFiltersController)
  application.register('filter-group', FilterGroupController)
  application.register('condition', ConditionController)
  application.register('applied-tags', AppliedTagsController)
  application.register('multi-select', MultiSelectController)
}
