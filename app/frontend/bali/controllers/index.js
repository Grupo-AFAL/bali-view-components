/**
 * Bali Stimulus Controllers
 *
 * These are utility controllers that can be used independently of ViewComponents.
 * Import individual controllers or use the registerAll helper.
 *
 * Usage:
 *   import { DatepickerController, registerAllControllers } from 'bali-view-components'
 *   registerAllControllers(application) // Register all controllers
 *   // OR
 *   application.register('datepicker', DatepickerController)
 */

import { AutoPlayAudioController } from '../../../assets/javascripts/bali/controllers/auto-play-audio-controller'
import { AutocompleteAddressController } from '../../../assets/javascripts/bali/controllers/autocomplete-address-controller'
import { CheckboxRevealController } from '../../../assets/javascripts/bali/controllers/checkbox-reveal-controller'
import { CheckboxToggleController } from '../../../assets/javascripts/bali/controllers/checkbox-toggle-controller'
import { EditModeController } from '../../../assets/javascripts/bali/controllers/edit-mode-controller'
import { DatepickerController } from '../../../assets/javascripts/bali/controllers/datepicker-controller'
import { DrawingMapsController } from '../../../assets/javascripts/bali/controllers/drawing-maps-controller'
import { DynamicFieldsController } from '../../../assets/javascripts/bali/controllers/dynamic-fields-controller'
import { ElementsOverlapController } from '../../../assets/javascripts/bali/controllers/elements-overlap-controller'
import { FileInputController } from '../../../assets/javascripts/bali/controllers/file-input-controller'
import { FilterPersistenceController } from '../../../assets/javascripts/bali/controllers/filter-persistence-controller'
import { FocusOnConnectController } from '../../../assets/javascripts/bali/controllers/focus-on-connect-controller'
import { GeocoderMapsController } from '../../../assets/javascripts/bali/controllers/geocoder-maps-controller'
import { InputOnChangeController } from '../../../assets/javascripts/bali/controllers/input-on-change-controller'
import { InteractController } from '../../../assets/javascripts/bali/controllers/interact-controller'
import { PrintController } from '../../../assets/javascripts/bali/controllers/print-controller'
import { RadioButtonsGroupController } from '../../../assets/javascripts/bali/controllers/radio-buttons-group-controller'
import { RadioToggleController } from '../../../assets/javascripts/bali/controllers/radio-toggle-controller'
import { SlimSelectController } from '../../../assets/javascripts/bali/controllers/slim-select-controller'
import { StepNumberInputController } from '../../../assets/javascripts/bali/controllers/step-number-input-controller'
import { SubmitButtonController } from '../../../assets/javascripts/bali/controllers/submit-button-controller'
import { SubmitOnChangeController } from '../../../assets/javascripts/bali/controllers/submit-on-change-controller'
import { TextareaController } from '../../../assets/javascripts/bali/controllers/textarea-controller'
import { TimePeriodFieldController } from '../../../assets/javascripts/bali/controllers/time-period-field-controller'
import { TrixAttachmentsController } from '../../../assets/javascripts/bali/controllers/trix-attachments-controller'

export {
  AutoPlayAudioController,
  AutocompleteAddressController,
  CheckboxRevealController,
  CheckboxToggleController,
  EditModeController,
  DatepickerController,
  DrawingMapsController,
  DynamicFieldsController,
  ElementsOverlapController,
  FileInputController,
  FilterPersistenceController,
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
}

/**
 * THE manifest of utility controllers: Stimulus identifier -> controller class.
 *
 * registerAll derives from this map; the named exports above exist so an app can
 * import one controller without pulling in the rest. scripts/check-controller-manifest.mjs
 * keeps the two lists and the source tree in sync.
 *
 * The @__PURE__ annotation lets bundlers drop the map (and with it every import
 * above) when a consumer only imports a single named controller.
 */
export const CONTROLLERS = /* @__PURE__ */ Object.freeze({
  'auto-play-audio': AutoPlayAudioController,
  'autocomplete-address': AutocompleteAddressController,
  'checkbox-reveal': CheckboxRevealController,
  'checkbox-toggle': CheckboxToggleController,
  datepicker: DatepickerController,
  'drawing-maps': DrawingMapsController,
  'dynamic-fields': DynamicFieldsController,
  'edit-mode': EditModeController,
  'elements-overlap': ElementsOverlapController,
  'file-input': FileInputController,
  'filter-persistence': FilterPersistenceController,
  'focus-on-connect': FocusOnConnectController,
  'geocoder-maps': GeocoderMapsController,
  'input-on-change': InputOnChangeController,
  interact: InteractController,
  print: PrintController,
  'radio-buttons-group': RadioButtonsGroupController,
  'radio-toggle': RadioToggleController,
  'slim-select': SlimSelectController,
  'step-number-input': StepNumberInputController,
  'submit-button': SubmitButtonController,
  'submit-on-change': SubmitOnChangeController,
  textarea: TextareaController,
  'time-period-field': TimePeriodFieldController,
  'trix-attachments': TrixAttachmentsController
})

/**
 * Register all Bali utility controllers with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerAll (application) {
  for (const [identifier, controller] of Object.entries(CONTROLLERS)) {
    application.register(identifier, controller)
  }
}
