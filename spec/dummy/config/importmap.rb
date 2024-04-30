# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.4/+esm"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "trix", to: 'https://cdn.jsdelivr.net/npm/trix@2.1.0/+esm'
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin '@rails/request.js', to: 'https://cdn.jsdelivr.net/npm/@rails/request.js@0.0.9/+esm'
pin '@googlemaps/markerclusterer', to: 'https://cdn.jsdelivr.net/npm/@googlemaps/markerclusterer@2.5.3/+esm'

pin "chart.js", to: 'https://cdn.jsdelivr.net/npm/chart.js@4.4.2/+esm'
pin "lodash.throttle", to: 'https://cdn.jsdelivr.net/npm/lodash.throttle@4.1.1/+esm'
pin "slim-select", to: 'https://cdn.jsdelivr.net/npm/slim-select@2.8.2/+esm'
pin "sortablejs", to: 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/+esm'
pin "tippy.js", to: 'https://cdn.jsdelivr.net/npm/tippy.js@6.3.7/+esm'
pin "@popperjs/core", to: 'https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/+esm'
pin "date-fns", to: 'https://cdn.jsdelivr.net/npm/date-fns@3.6.0/+esm'
pin "date-fns/locale/en-US", to: 'https://cdn.jsdelivr.net/npm/date-fns@3.6.0/locale/en-US/+esm'
pin "date-fns/locale/es", to: 'https://cdn.jsdelivr.net/npm/date-fns@3.6.0/locale/es/+esm'

pin "bali/utils/domHelpers", to: 'bali/utils/domHelpers.js'
pin "bali/utils/google-maps-loader", to: 'bali/utils/google-maps-loader.js'
pin "bali/utils/formatters", to: 'bali/utils/formatters.js'
pin "bali/utils/form", to: 'bali/utils/form.js'
pin "bali/utils/use-click-outside", to: 'bali/utils/use-click-outside.js'
pin "bali/utils/time", to: 'bali/utils/time.js'
pin "bali/utils/use-dispatch", to: 'bali/utils/use-dispatch.js'

pin 'bali/auto-play-audio-controller', to: 'bali/controllers/auto-play-audio-controller'
pin 'bali/autocomplete-address-controller', to: 'bali/controllers/autocomplete-address-controller'
pin 'bali/checkbox-toggle-controller', to: 'bali/controllers/checkbox-toggle-controller'
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
pin 'bali/trix-attachments-controller', to: 'bali/controllers/trix-attachments-controller'

pin 'bali/avatar', to: 'bali/avatar/index.js'
pin 'bali/bulk_actions', to: 'bali/bulk_actions/index.js'
pin 'bali/carousel', to: 'bali/carousel/index.js'
pin 'bali/chart', to: 'bali/chart/index.js'
pin 'bali/clipboard', to: 'bali/clipboard/index.js'
pin 'bali/drawer', to: 'bali/drawer/index.js'
pin 'bali/dropdown', to: 'bali/dropdown/index.js'
pin 'bali/gantt_chart', to: 'bali/gantt_chart/index.js'
pin 'bali/hover_card', to: 'bali/hover_card/index.js'
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
pin 'bali/filters/filter-form', to: 'bali/filters/controllers/filter-form-controller.js'
pin 'bali/filters/popup', to: 'bali/filters/controllers/popup-controller.js'
pin 'bali/filters/selected', to: 'bali/filters/controllers/selected-controller.js'
pin "lodash.debounce", to: 'https://cdn.jsdelivr.net/npm/lodash.debounce@4.0.8/+esm'

pin 'bali/rich_text_editor', to: 'bali/rich_text_editor/index.js'
pin 'bali/rich_text_editor/extensions/slashCommands', to: 'bali/rich_text_editor/javascript/extensions/slashCommands.js'
pin 'bali/rich_text_editor/suggestions/commandsOptions', to: 'bali/rich_text_editor/javascript/suggestions/commands_options.js'
pin 'bali/rich_text_editor/suggestions/pagesOptions', to: 'bali/rich_text_editor/javascript/suggestions/pages_options.js'
pin 'bali/rich_text_editor/suggestions/popupListComponent', to: 'bali/rich_text_editor/javascript/suggestions/popup_list_component.js'
pin 'bali/rich_text_editor/suggestions/renderer', to: 'bali/rich_text_editor/javascript/suggestions/renderer.js'
pin 'bali/rich_text_editor/lowlight', to: 'bali/rich_text_editor/javascript/lowlight.js'
pin 'bali/rich_text_editor/useDefaults', to: 'bali/rich_text_editor/javascript/useDefaults.js'
pin 'bali/rich_text_editor/useImage', to: 'bali/rich_text_editor/javascript/useImage.js'
pin 'bali/rich_text_editor/useLink', to: 'bali/rich_text_editor/javascript/useLink.js'
pin 'bali/rich_text_editor/useMarks', to: 'bali/rich_text_editor/javascript/useMarks.js'
pin 'bali/rich_text_editor/useMention', to: 'bali/rich_text_editor/javascript/useMention.js'
pin 'bali/rich_text_editor/useNodes', to: 'bali/rich_text_editor/javascript/useNodes.js'
pin 'bali/rich_text_editor/useSlashCommands', to: 'bali/rich_text_editor/javascript/useSlashCommands.js'
pin 'bali/rich_text_editor/useTable', to: 'bali/rich_text_editor/javascript/useTable.js'
pin "lowlight", to: 'https://cdn.jsdelivr.net/npm/lowlight@3.1.0/+esm'
pin "devlop", to: 'https://cdn.jsdelivr.net/npm/devlop@1.1.0/+esm'
pin "highlight.js/lib/languages/javascript", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/javascript.min.js'
pin "highlight.js/lib/languages/json", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/json.min.js'
pin "highlight.js/lib/languages/ruby", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/ruby.min.js'
pin "highlight.js/lib/languages/scss", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/scss.min.js'
pin "highlight.js/lib/languages/sql", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/sql.min.js'
pin "highlight.js/lib/languages/xml", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/xml.min.js'
pin "highlight.js/lib/languages/yaml", to: 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/yaml.min.js'

pin "@tiptap/core", to: 'https://cdn.jsdelivr.net/npm/@tiptap/core@2.3.0/+esm'
pin "@tiptap/pm/commands", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/commands/+esm"
pin "@tiptap/pm/keymap", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/keymap/+esm"
pin "@tiptap/pm/model", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/model/+esm"
pin "@tiptap/pm/schema-list", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/schema-list/+esm"
pin "@tiptap/pm/state", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/state/+esm"
pin "@tiptap/pm/transform", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/transform/+esm"
pin "@tiptap/pm/view", to: "https://cdn.jsdelivr.net/npm/@tiptap/pm@2.3.0/view/+esm"
pin "orderedmap", to: 'https://cdn.jsdelivr.net/npm/orderedmap@2.1.1/+esm'
pin "prosemirror-commands", to: 'https://cdn.jsdelivr.net/npm/prosemirror-commands@1.5.2/+esm'
pin "prosemirror-keymap", to: 'https://cdn.jsdelivr.net/npm/prosemirror-keymap@1.2.2/+esm'
pin "prosemirror-model", to: 'https://cdn.jsdelivr.net/npm/prosemirror-model@1.20.0/+esm'
pin "prosemirror-schema-list", to: 'https://cdn.jsdelivr.net/npm/prosemirror-schema-list@1.3.0/+esm'
pin "prosemirror-state", to: 'https://cdn.jsdelivr.net/npm/prosemirror-state@1.4.3/+esm'
pin "prosemirror-transform", to: 'https://cdn.jsdelivr.net/npm/prosemirror-transform@1.8.0/+esm'
pin "prosemirror-view", to: 'https://cdn.jsdelivr.net/npm/prosemirror-view@1.33.5/+esm'
pin "w3c-keyname", to: 'https://cdn.jsdelivr.net/npm/w3c-keyname@2.2.8/+esm'
pin "@tiptap/suggestion", to: 'https://cdn.jsdelivr.net/npm/@tiptap/suggestion@2.3.0/+esm'
