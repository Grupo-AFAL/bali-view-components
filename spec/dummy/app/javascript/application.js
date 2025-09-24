// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { application } from 'controllers/application'
import { Turbo } from '@hotwired/turbo-rails'
import * as ActiveStorage from '@rails/activestorage'
import 'controllers'

import { AutoPlayAudioController } from 'bali/auto-play-audio-controller'
import { AutocompleteAddressController } from 'bali/autocomplete-address-controller'
import { CheckboxToggleController } from 'bali/checkbox-toggle-controller'
import { CheckboxRevealController } from 'bali/checkbox-reveal-controller'
import { DatepickerController } from 'bali/datepicker-controller'
import { DrawingMapsController } from 'bali/drawing-maps-controller'
import { DynamicFieldsController } from 'bali/dynamic-fields-controller'
import { ElementsOverlapController } from 'bali/elements-overlap-controller'
import { FileInputController } from 'bali/file-input-controller'
import { FocusOnConnectController } from 'bali/focus-on-connect-controller'
import { GeocoderMapsController } from 'bali/geocoder-maps-controller'
import { InputOnChangeController } from 'bali/input-on-change-controller'
import { InteractController } from 'bali/interact-controller'
import { PrintController } from 'bali/print-controller'
import { RadioButtonsGroupController } from 'bali/radio-buttons-group-controller'
import { RadioToggleController } from 'bali/radio-toggle-controller'
import { SlimSelectController } from 'bali/slim-select-controller'
import { StepNumberInputController } from 'bali/step-number-input-controller'
import { SubmitButtonController } from 'bali/submit-button-controller'
import { SubmitOnChangeController } from 'bali/submit-on-change-controller'
import { TrixAttachmentsController } from 'bali/trix-attachments-controller'
import { RecurrentEventRuleController } from 'bali/recurrent-event-rule'
import { TimePeriodFieldController } from 'bali/time-period-field-controller'

import { AvatarController } from 'bali/avatar'
import { BulkActionsController } from 'bali/bulk_actions'
import { CarouselController } from 'bali/carousel'
import { ChartController } from 'bali/chart'
import { ClipboardController } from 'bali/clipboard'
import { DrawerController } from 'bali/drawer'
import { DropdownController } from 'bali/dropdown'
import { GanttFoldableItemController } from 'bali/gantt-chart/foldable-item'
import { GanttChartController } from 'bali/gantt-chart'
import { HovercardController } from 'bali/hovercard'
import { LocationsMapController } from 'bali/locations_map'
import { ModalController } from 'bali/modal'
import { NavbarController } from 'bali/navbar'
import { NotificationController } from 'bali/notification'
import { RateController } from 'bali/rate'
import { RevealController } from 'bali/reveal'
import { RichTextEditorController } from 'bali/rich_text_editor'
import { SideMenuController } from 'bali/side_menu'
import { SortableListController } from 'bali/sortable_list'
import { TableController } from 'bali/table'
import { TabsController } from 'bali/tabs'
import { TimeagoController } from 'bali/timeago'
import { TooltipController } from 'bali/tooltip'
import { TreeViewItemController } from 'bali/tree_view/item'
import { TurboNativeAppSignOut } from 'bali/turbo_native_app/sign_out'
import { FilterTextInputsManagerController } from 'bali/filters/filter-text-inputs-manager'
import { FilterAttributeController } from 'bali/filters/filter-attribute'
import { FilterFormController } from 'bali/filters/filter-form'
import { PopupController } from 'bali/filters/popup'
import { SelectedController } from 'bali/filters/selected'

ActiveStorage.start()

window.Turbo = Turbo

application.register('avatar', AvatarController)
application.register('bulk-actions', BulkActionsController)
application.register('carousel', CarouselController)
application.register('chart', ChartController)
application.register('clipboard', ClipboardController)
application.register('drawer', DrawerController)
application.register('dropdown', DropdownController)
application.register('gantt-foldable-item', GanttFoldableItemController)
application.register('gantt-chart', GanttChartController)
application.register('hovercard', HovercardController)
application.register('locations-map', LocationsMapController)
application.register('modal', ModalController)
application.register('navbar', NavbarController)
application.register('notification', NotificationController)
application.register('rate', RateController)
application.register('reveal', RevealController)
application.register('rich-text-editor', RichTextEditorController)
application.register('side-menu', SideMenuController)
application.register('sortable-list', SortableListController)
application.register('table', TableController)
application.register('tabs', TabsController)
application.register('timeago', TimeagoController)
application.register('tooltip', TooltipController)
application.register('tree-view-item', TreeViewItemController)
application.register('turbo-native-app-sign-out', TurboNativeAppSignOut)
application.register('filter-text-inputs-manager', FilterTextInputsManagerController)
application.register('filter-attribute', FilterAttributeController)
application.register('filter-form', FilterFormController)
application.register('popup', PopupController)
application.register('selected', SelectedController)

application.register('auto-play-audio', AutoPlayAudioController)
application.register('autocomplete-address', AutocompleteAddressController)
application.register('checkbox-toggle', CheckboxToggleController)
application.register('checkbox-reveal', CheckboxRevealController)
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
application.register('recurrent-event-rule', RecurrentEventRuleController)
