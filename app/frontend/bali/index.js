/**
 * Bali ViewComponents - JavaScript Entry Point
 *
 * This is the main entry point for consuming Bali's JavaScript.
 * It provides access to all Stimulus controllers and utilities.
 *
 * ## Quick Start
 *
 *   import { registerAll } from 'bali-view-components'
 *   registerAll(application)
 *
 * ## Selective Imports (tree-shaking)
 *
 * Core controllers:
 *   import { DatepickerController, TableController } from 'bali-view-components'
 *
 * Optional modules (import separately to reduce bundle size):
 *   import { ChartController, registerCharts } from 'bali-view-components/charts'
 *   import { GanttChartController, registerGantt } from 'bali-view-components/gantt'
 *   import { RichTextEditorController } from 'bali-view-components/rich-text-editor'
 *
 * ## Setup in consuming app
 *
 * No bundler configuration needed. Just install the package and import.
 *
 * ### esbuild (Rails default)
 *
 *   // application.js
 *   import { Application } from '@hotwired/stimulus'
 *   import { registerAll } from 'bali-view-components'
 *
 *   const application = Application.start()
 *   registerAll(application)
 *
 * ### Vite
 *
 *   // Same imports work with Vite. May need fs.allow for gem path:
 *   server: { fs: { allow: ['.', baliGemPath] } }
 *
 * ## Usage in application.js:
 *
 *   // Register all core controllers at once
 *   import { registerAll } from 'bali-view-components'
 *   registerAll(application)
 *
 *   // Add optional modules as needed
 *   import { registerCharts } from 'bali-view-components/charts'
 *   import { registerGantt } from 'bali-view-components/gantt'
 *   registerCharts(application)
 *   registerGantt(application)
 */

// Re-export all utility controllers
// Import registerAll functions for the combined registerAll export
import { registerAll as registerControllers } from './controllers/index'
import { registerAll as registerComponents } from './components/index'

// Re-export individual controllers (excluding registerAll to avoid conflicts)
export {
  AutoPlayAudioController,
  AutocompleteAddressController,
  CheckboxRevealController,
  CheckboxToggleController,
  DatepickerController,
  DrawingMapsController,
  DynamicFieldsController,
  ElementsOverlapController,
  FileInputController,
  FocusOnConnectController,
  GeocoderMapsController,
  InputOnChangeController,
  InteractController,
  PrintController,
  RadioButtonsGroupController,
  RadioToggleController,
  SlimSelectController,
  StepNumberInputController,
  SubmitButtonController,
  SubmitOnChangeController,
  TextareaController,
  TimePeriodFieldController,
  TrixAttachmentsController
} from './controllers/index'
export { registerAll as registerAllControllers } from './controllers/index'

// Re-export all core component controllers (excludes heavy modules)
export {
  FiltersController,
  AppliedTagsController,
  AvatarController,
  BulkActionsController,
  CarouselController,
  ClipboardController,
  ConditionController,
  DirectUploadController,
  DrawerController,
  DropdownController,
  FilterGroupController,
  HovercardController,
  ImageFieldController,
  LocationsMapController,
  ModalController,
  MultiSelectController,
  NavbarController,
  NotificationController,
  RateController,
  RecurrentEventRuleController,
  RevealController,
  SideMenuController,
  SortableListController,
  TabsController,
  TableController,
  TimeagoController,
  TooltipController,
  TreeViewItemController
} from './components/index'
export { registerAll as registerAllComponents } from './components/index'

// Re-export utilities
export * from './utils/index'

/**
 * Register ALL core Bali controllers (utility + component controllers)
 *
 * NOTE: Heavy/optional modules are NOT included. Import them separately:
 *   - import { registerCharts } from 'bali-view-components/charts'
 *   - import { registerGantt } from 'bali-view-components/gantt'
 *   - import { registerRichTextEditor } from 'bali-view-components/rich-text-editor'
 *
 * @param {Application} application - Stimulus application instance
 */
export function registerAll (application) {
  registerControllers(application)
  registerComponents(application)
}
