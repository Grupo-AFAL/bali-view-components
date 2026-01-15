/**
 * Bali Stimulus Controllers
 *
 * These are utility controllers that can be used independently of ViewComponents.
 * Import individual controllers or use the registerAll helper.
 *
 * Usage with Vite:
 *   import { DatepickerController, registerAll } from 'bali/controllers'
 *   registerAll(application) // Register all controllers
 *   // OR
 *   application.register('datepicker', DatepickerController)
 */

// Re-export all controllers from the assets directory
// Import all for registerAll (static imports - tree-shaking will remove unused)
import { AutoPlayAudioController } from '../../../assets/javascripts/bali/controllers/auto-play-audio-controller'
import { AutocompleteAddressController } from '../../../assets/javascripts/bali/controllers/autocomplete-address-controller'
import { CheckboxRevealController } from '../../../assets/javascripts/bali/controllers/checkbox-reveal-controller'
import { CheckboxToggleController } from '../../../assets/javascripts/bali/controllers/checkbox-toggle-controller'
import { DatepickerController } from '../../../assets/javascripts/bali/controllers/datepicker-controller'
import { DrawingMapsController } from '../../../assets/javascripts/bali/controllers/drawing-maps-controller'
import { DynamicFieldsController } from '../../../assets/javascripts/bali/controllers/dynamic-fields-controller'
import { ElementsOverlapController } from '../../../assets/javascripts/bali/controllers/elements-overlap-controller'
import { FileInputController } from '../../../assets/javascripts/bali/controllers/file-input-controller'
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
import { TimePeriodFieldController } from '../../../assets/javascripts/bali/controllers/time-period-field-controller'
import { TrixAttachmentsController } from '../../../assets/javascripts/bali/controllers/trix-attachments-controller'

export { AutoPlayAudioController } from '../../../assets/javascripts/bali/controllers/auto-play-audio-controller'
export { AutocompleteAddressController } from '../../../assets/javascripts/bali/controllers/autocomplete-address-controller'
export { CheckboxRevealController } from '../../../assets/javascripts/bali/controllers/checkbox-reveal-controller'
export { CheckboxToggleController } from '../../../assets/javascripts/bali/controllers/checkbox-toggle-controller'
export { DatepickerController } from '../../../assets/javascripts/bali/controllers/datepicker-controller'
export { DrawingMapsController } from '../../../assets/javascripts/bali/controllers/drawing-maps-controller'
export { DynamicFieldsController } from '../../../assets/javascripts/bali/controllers/dynamic-fields-controller'
export { ElementsOverlapController } from '../../../assets/javascripts/bali/controllers/elements-overlap-controller'
export { FileInputController } from '../../../assets/javascripts/bali/controllers/file-input-controller'
export { FocusOnConnectController } from '../../../assets/javascripts/bali/controllers/focus-on-connect-controller'
export { GeocoderMapsController } from '../../../assets/javascripts/bali/controllers/geocoder-maps-controller'
export { InputOnChangeController } from '../../../assets/javascripts/bali/controllers/input-on-change-controller'
export { InteractController } from '../../../assets/javascripts/bali/controllers/interact-controller'
export { PrintController } from '../../../assets/javascripts/bali/controllers/print-controller'
export { RadioButtonsGroupController } from '../../../assets/javascripts/bali/controllers/radio-buttons-group-controller'
export { RadioToggleController } from '../../../assets/javascripts/bali/controllers/radio-toggle-controller'
export { SlimSelectController } from '../../../assets/javascripts/bali/controllers/slim-select-controller'
export { StepNumberInputController } from '../../../assets/javascripts/bali/controllers/step-number-input-controller'
export { SubmitButtonController } from '../../../assets/javascripts/bali/controllers/submit-button-controller'
export { SubmitOnChangeController } from '../../../assets/javascripts/bali/controllers/submit-on-change-controller'
export { TimePeriodFieldController } from '../../../assets/javascripts/bali/controllers/time-period-field-controller'
export { TrixAttachmentsController } from '../../../assets/javascripts/bali/controllers/trix-attachments-controller'

/**
 * Register all Bali utility controllers with a Stimulus application
 * @param {Application} application - Stimulus application instance
 */
export function registerAll (application) {
  application.register('auto-play-audio', AutoPlayAudioController)
  application.register('autocomplete-address', AutocompleteAddressController)
  application.register('checkbox-reveal', CheckboxRevealController)
  application.register('checkbox-toggle', CheckboxToggleController)
  application.register('datepicker', DatepickerController)
  application.register('drawing-maps', DrawingMapsController)
  application.register('dynamic-fields', DynamicFieldsController)
  application.register('elements-overlap', ElementsOverlapController)
  application.register('file-input', FileInputController)
  application.register('focus-on-connect', FocusOnConnectController)
  application.register('geocoder-maps', GeocoderMapsController)
  application.register('input-on-change', InputOnChangeController)
  application.register('interact', InteractController)
  application.register('print', PrintController)
  application.register('radio-buttons-group', RadioButtonsGroupController)
  application.register('radio-toggle', RadioToggleController)
  application.register('slim-select', SlimSelectController)
  application.register('step-number-input', StepNumberInputController)
  application.register('submit-button', SubmitButtonController)
  application.register('submit-on-change', SubmitOnChangeController)
  application.register('time-period-field', TimePeriodFieldController)
  application.register('trix-attachments', TrixAttachmentsController)
}
