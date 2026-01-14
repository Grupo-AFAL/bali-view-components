# Pin npm packages by running ./bin/importmap

# Load Rich Text Editor importmap only if explicitly enabled
# Set ENABLE_RICH_TEXT_EDITOR=1 to load TipTap dependencies
if ENV['ENABLE_RICH_TEXT_EDITOR']
  require_relative '../../../lib/bali/importmap/rich_text_editor'
end

pin "application"

# Rails
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin '@rails/request.js', to: 'https://cdn.jsdelivr.net/npm/@rails/request.js@0.0.12/+esm'

# Hotwired
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.16/+esm"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Stimulus controllers
pin_all_from "app/javascript/controllers", under: "controllers"

# Maps (Locations maps / Drawing maps)
pin '@googlemaps/markerclusterer', to: 'https://cdn.jsdelivr.net/npm/@googlemaps/markerclusterer@2.6.2/+esm'

# Trix
pin "trix", to: 'https://cdn.jsdelivr.net/npm/trix@2.1.15/+esm'

# Chart.js
pin "chart.js", to: 'https://cdn.jsdelivr.net/npm/chart.js@4.5.0/+esm'

# Slim select
pin "slim-select", to: 'https://cdn.jsdelivr.net/npm/slim-select@2.12.1/+esm'

# Sortable
pin "sortablejs", to: 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/+esm'

# Hovercard / Tooltip
pin "tippy.js", to: 'https://cdn.jsdelivr.net/npm/tippy.js@6.3.7/+esm'
pin "@popperjs/core", to: 'https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/+esm'

# Date fns (es / en) Timeago
pin "date-fns", to: 'https://cdn.jsdelivr.net/npm/date-fns@4.1.0/+esm'
pin "date-fns/locale/en-US", to: 'https://cdn.jsdelivr.net/npm/date-fns@4.1.0/locale/en-US/+esm'
pin "date-fns/locale/es", to: 'https://cdn.jsdelivr.net/npm/date-fns@4.1.0/locale/es/+esm'

# Flatpickr (Datepicker)
pin 'flatpickr', to: 'https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/+esm'
pin 'flatpickr/dist/l10n/es.js', to: 'https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/l10n/es.js'

# Lodash throttle/debounce
pin "lodash.throttle", to: 'https://cdn.jsdelivr.net/npm/lodash.throttle@4.1.1/+esm'
pin "lodash.debounce", to: 'https://cdn.jsdelivr.net/npm/lodash.debounce@4.0.8/+esm'

# Bali Utils
pin "bali/utils/domHelpers", to: 'bali/utils/domHelpers.js'
pin "bali/utils/google-maps-loader", to: 'bali/utils/google-maps-loader.js'
pin "bali/utils/formatters", to: 'bali/utils/formatters.js'
pin "bali/utils/form", to: 'bali/utils/form.js'
pin "bali/utils/use-click-outside", to: 'bali/utils/use-click-outside.js'
pin "bali/utils/time", to: 'bali/utils/time.js'
pin "bali/utils/use-dispatch", to: 'bali/utils/use-dispatch.js'

# Bali Stimulus Controllers
pin 'bali/auto-play-audio-controller', to: 'bali/controllers/auto-play-audio-controller'
pin 'bali/autocomplete-address-controller', to: 'bali/controllers/autocomplete-address-controller'
pin 'bali/checkbox-toggle-controller', to: 'bali/controllers/checkbox-toggle-controller'
pin 'bali/checkbox-reveal-controller', to: 'bali/controllers/checkbox-reveal-controller'
pin 'bali/datepicker-controller', to: 'bali/controllers/datepicker-controller'
pin 'bali/drawing-maps-controller', to: 'bali/controllers/drawing-maps-controller'
pin 'bali/dynamic-fields-controller', to: 'bali/controllers/dynamic-fields-controller'
pin 'bali/elements-overlap-controller', to: 'bali/controllers/elements-overlap-controller'
pin 'bali/file-input-controller', to: 'bali/controllers/file-input-controller'
pin 'bali/focus-on-connect-controller', to: 'bali/controllers/focus-on-connect-controller'
pin 'bali/geocoder-maps-controller', to: 'bali/controllers/geocoder-maps-controller'
pin 'bali/input-on-change-controller', to: 'bali/controllers/input-on-change-controller'
pin 'bali/interact-controller', to: 'bali/controllers/interact-controller'
pin 'bali/print-controller', to: 'bali/controllers/print-controller'
pin 'bali/radio-buttons-group-controller', to: 'bali/controllers/radio-buttons-group-controller'
pin 'bali/radio-toggle-controller', to: 'bali/controllers/radio-toggle-controller'
pin 'bali/slim-select-controller', to: 'bali/controllers/slim-select-controller'
pin 'bali/step-number-input-controller', to: 'bali/controllers/step-number-input-controller'
pin 'bali/submit-button-controller', to: 'bali/controllers/submit-button-controller'
pin 'bali/submit-on-change-controller', to: 'bali/controllers/submit-on-change-controller'
pin 'bali/time-period-field-controller', to: 'bali/controllers/time-period-field-controller'
pin 'bali/trix-attachments-controller', to: 'bali/controllers/trix-attachments-controller'

# Bali Components (Javascript)
pin 'bali/avatar', to: 'bali/avatar/index.js'
pin 'bali/bulk_actions', to: 'bali/bulk_actions/index.js'
pin 'bali/carousel', to: 'bali/carousel/index.js'
pin 'bali/chart', to: 'bali/chart/index.js'
pin 'bali/clipboard', to: 'bali/clipboard/index.js'
pin 'bali/drawer', to: 'bali/drawer/index.js'
pin 'bali/dropdown', to: 'bali/dropdown/index.js'
pin 'bali/gantt-chart/connection-line', to: 'bali/gantt_chart/connection_line.js'
pin 'bali/gantt-chart/foldable-item', to: 'bali/gantt_chart/gantt_foldable_item.js'
pin 'bali/gantt-chart', to: 'bali/gantt_chart/index.js'
pin 'bali/hovercard', to: 'bali/hover_card/index.js'
pin 'bali/image-field', to: 'bali/image_field/index.js'
pin 'bali/locations_map', to: 'bali/locations_map/index.js'
pin 'bali/modal', to: 'bali/modal/index.js'
pin 'bali/navbar', to: 'bali/navbar/index.js'
pin 'bali/notification', to: 'bali/notification/index.js'
pin 'bali/rate', to: 'bali/rate/index.js'
pin 'bali/reveal', to: 'bali/reveal/index.js'
pin 'bali/side_menu', to: 'bali/side_menu/index.js'
pin 'bali/sortable_list', to: 'bali/sortable_list/index.js'
pin 'bali/table', to: 'bali/table/index.js'
pin 'bali/tabs', to: 'bali/tabs/index.js'
pin 'bali/timeago', to: 'bali/timeago/index.js'
pin 'bali/tooltip', to: 'bali/tooltip/index.js'
pin 'bali/tree_view/item', to: 'bali/tree_view/item/index.js'
pin 'bali/turbo_native_app/sign_out', to: 'bali/turbo_native_app/sign_out/index.js'
pin 'bali/filters/filter-attribute', to: 'bali/filters/controllers/filter-attribute-controller.js'
pin 'bali/filters/filter-text-inputs-manager', to: 'bali/filters/controllers/filter-text-inputs-manager-controller.js'
pin 'bali/filters/filter-form', to: 'bali/filters/controllers/filter-form-controller.js'
pin 'bali/filters/popup', to: 'bali/filters/controllers/popup-controller.js'
pin 'bali/filters/selected', to: 'bali/filters/controllers/selected-controller.js'
pin 'bali/recurrent-event-rule', to: 'bali/recurrent_event_rule_form/index.js'

pin 'rrule', to: 'https://cdn.jsdelivr.net/npm/rrule@2.8.1/+esm'

# Rich Text Editor - Conditionally loaded
# Set ENABLE_RICH_TEXT_EDITOR=1 environment variable to load TipTap dependencies
if ENV['ENABLE_RICH_TEXT_EDITOR']
  Bali::Importmap::RichTextEditor.pin_all(self)
end
