/**
 * Bali ViewComponents - JavaScript Entry Point for Vite
 *
 * This is the main entry point for consuming Bali's JavaScript with Vite.
 * It provides access to all Stimulus controllers and utilities.
 *
 * ## Package Structure
 *
 * Core (lightweight, always needed):
 *   import { DatepickerController, TableController } from 'bali'
 *
 * Optional modules (import separately to reduce bundle size):
 *   import { ChartController, registerCharts } from 'bali/charts'
 *   import { GanttChartController, registerGantt } from 'bali/gantt'
 *   import { RichTextEditorController } from 'bali/rich-text-editor'  // WARNING: broken
 *
 * ## Setup in consuming app's vite.config.mts:
 *
 *   import { resolve, dirname } from 'path'
 *   import { fileURLToPath } from 'url'
 *
 *   const __dirname = dirname(fileURLToPath(import.meta.url))
 *   const baliGemPath = resolve(__dirname, 'vendor/bundle/ruby/3.x.x/gems/bali_view_components-x.x.x')
 *   // Or dynamically: execSync('bundle show bali_view_components').toString().trim()
 *
 *   export default defineConfig({
 *     resolve: {
 *       alias: {
 *         'bali': resolve(baliGemPath, 'app/frontend/bali')
 *       }
 *     },
 *     server: {
 *       fs: { allow: ['.', baliGemPath] }
 *     }
 *   })
 *
 * ## Usage in application.js:
 *
 *   // Register all core controllers at once
 *   import { registerAllControllers, registerAllComponents } from 'bali'
 *   registerAllControllers(application)
 *   registerAllComponents(application)
 *
 *   // Add optional modules as needed
 *   import { registerCharts } from 'bali/charts'
 *   import { registerGantt } from 'bali/gantt'
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
  TimePeriodFieldController,
  TrixAttachmentsController
} from './controllers/index'
export { registerAll as registerAllControllers } from './controllers/index'

// Re-export all core component controllers (excludes heavy modules)
export {
  AdvancedFiltersController,
  AppliedTagsController,
  AvatarController,
  BulkActionsController,
  CarouselController,
  ClipboardController,
  ConditionController,
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
  TooltipController
} from './components/index'
export { registerAll as registerAllComponents } from './components/index'

// Re-export utilities
export * from './utils/index'

/**
 * Register ALL core Bali controllers (utility + component controllers)
 *
 * NOTE: Heavy/optional modules are NOT included. Import them separately:
 *   - import { registerCharts } from 'bali/charts'
 *   - import { registerGantt } from 'bali/gantt'
 *   - import { registerRichTextEditor } from 'bali/rich-text-editor'
 *
 * @param {Application} application - Stimulus application instance
 */
export function registerAll (application) {
  registerControllers(application)
  registerComponents(application)
}
