# frozen_string_literal: true

module Bali
  module DataTable
    module SimpleFilters
      # SimpleFilters provides inline dropdown filters for DataTable.
      # Unlike the complex Filters component, SimpleFilters renders as a simple
      # row of select dropdowns with a submit button - no popovers, no AND/OR
      # groupings, no operator selection.
      #
      # @example Via DataTable slot (auto-configured from FilterForm)
      #   data_table.with_simple_filters
      #
      # @example With explicit filters
      #   data_table.with_simple_filters(filters: [
      #     { attribute: :status, collection: [...], blank: "All", label: "Status" }
      #   ])
      #
      class Component < ApplicationViewComponent
        include Utils::Url
        include Bali::Filters::PreservedParams
        include Bali::Filters::Persistable

        # Min-width for slim_select dropdowns. Triggers in SimpleFilters are narrow
        # (~13rem), so we let the dropdown grow past the trigger to fit long labels
        # without wrapping.
        SLIM_SELECT_CONTENT_WIDTH = ">240px"

        # @param url [String] Form submission URL
        # @param filters [Array<Hash>] Filter configurations
        # @param show_clear [Boolean] Show clear button
        # @param search [Hash, nil] Search input configuration (see Bali::SearchConfig)
        #   - :fields [Array<Symbol>] Columns to search (e.g., [:name, :email]);
        #     Bali derives the Ransack param name from them
        #   - :value [String, nil] Current search value
        #   - :placeholder [String, nil] Placeholder text
        #   - :label [String, nil] Accessible name for the search input
        #   - :icon [String, nil] Icon rendered as a leading addon
        #   - :width [String, nil] Tailwind width classes (default: "w-48 sm:w-96")
        # @param storage_id [String, nil] Optional storage ID indicating filters can be persisted
        # @param persist_enabled [Boolean] Whether user has opted into filter persistence
        # @param persistence_toggle [Boolean] Render the bookmark toggle inline (default: true).
        #   DataTable turns it off and paints it as its own toolbar control.
        # @param preserved_params [Hash] Extra top-level params (e.g. an active
        #   `group_by`) rendered as hidden fields so the GET submit keeps them.
        #   Non-filter params already in the `url:` query string travel too
        #   (same semantics as Filters::Component); on a key collision the
        #   explicit hash wins.
        # rubocop:disable Metrics/ParameterLists
        def initialize(url:, filters: [], show_clear: false, search: nil, storage_id: nil,
                       persist_enabled: false, persistence_toggle: true, preserved_params: {})
          # rubocop:enable Metrics/ParameterLists
          @url = url
          @filters = filters
          @show_clear = show_clear
          @search = Bali::SearchConfig.wrap(search)
          @storage_id = storage_id
          @persist_enabled = persist_enabled
          @persistence_toggle = persistence_toggle
          @preserved_params = preserved_params || {}
        end

        def render?
          @filters.any? || search_enabled?
        end

        def show_clear?
          @show_clear
        end

        def search_enabled?
          @search.enabled?
        end

        # "q[name_or_email_cont]"
        def search_field_name
          @search.param_name
        end

        def search_value
          @search.value
        end

        def search_placeholder
          @search.placeholder
        end

        def search_icon
          @search.icon
        end

        def search_width
          @search.width.presence || "w-48 sm:w-96"
        end

        def filter_type(filter)
          filter[:type]&.to_sym
        end

        def toggle_group?(filter)
          filter_type(filter) == :toggle_group
        end

        def slim_select?(filter)
          filter_type(filter) == :slim_select
        end

        def date?(filter)
          filter_type(filter) == :date
        end

        def date_range?(filter)
          filter_type(filter) == :date_range
        end

        def date_filter?(filter)
          date?(filter) || date_range?(filter)
        end

        # A date range offered as named periods ("This month") with the picker behind a
        # "Custom…" option. Only `date_range` gets them: "this week" is not a value a
        # single date can hold.
        def presets?(filter)
          date_range?(filter) && filter[:presets].present?
        end

        def boolean?(filter)
          filter_type(filter) == :boolean
        end

        def radio_group?(filter)
          filter_type(filter) == :radio_group
        end

        def number_range?(filter)
          filter_type(filter) == :number_range
        end

        def select?(filter)
          filter_type(filter) == :select
        end

        def filter_field_name(filter)
          predicate = filter[:predicate] || (date_range?(filter) ? nil : :eq)
          name = predicate.present? ? "q[#{filter[:attribute]}_#{predicate}]" : "q[#{filter[:attribute]}]"
          toggle_group?(filter) ? "#{name}[]" : name
        end

        # The period select's options: "no filter", the declared presets, "Custom…".
        # The picker itself is a fourth state of the same control, not a fifth option.
        def preset_options(filter)
          [ [ preset_blank_label(filter), "" ] ] +
            Bali::DateRangePresets.options(filter[:presets]) +
            [ [ t("bali_view.simple_filters.presets.custom"), Bali::DateRangePresets::CUSTOM ] ]
        end

        # A date range filter has no blank option to name today, so `blank:` is free for it
        # and most call sites will not have bothered.
        def preset_blank_label(filter)
          filter[:blank].presence || t("bali_view.simple_filters.presets.any")
        end

        # Which option the request came back on. Anything that is not a token but is set is
        # a range the user typed or picked, so the select lands on "Custom…" and the picker
        # comes back holding it.
        def preset_select_value(filter)
          value = preset_current_value(filter)
          return "" if value.blank?

          Bali::DateRangePresets.token?(value) ? value : Bali::DateRangePresets::CUSTOM
        end

        def preset_custom_value(filter)
          value = preset_current_value(filter)
          Bali::DateRangePresets.token?(value) ? nil : value
        end

        # The one control that submits. Rendered with the value the request carried so the
        # form is correct before Stimulus connects — the controller rewrites it from
        # whichever control the user touches afterwards.
        def preset_current_value(filter)
          (filter[:value] || filter[:default]).presence&.to_s
        end

        def number_range_field_names(filter)
          {
            min: "q[#{filter[:attribute]}_gteq]",
            max: "q[#{filter[:attribute]}_lteq]"
          }
        end

        def number_range_values(filter)
          values = filter[:value] || filter[:default] || {}
          values = {} unless values.is_a?(Hash)
          values
        end

        # The visible caption above the control. `label: false` removes it on purpose
        # (#882), and a hand-written filter hash may not carry the key at all: both cases
        # are "no caption".
        #
        # It is kept apart from the accessible name because the two questions are answered
        # the other way round: the caption is PRINTED when it exists, the `aria-label` is
        # emitted when it does NOT. A single helper cannot serve both — the boolean toggle
        # paints its caption next to the switch and at the same time needs a name when it
        # has none.
        def filter_caption(filter)
          filter[:label].presence
        end

        def captioned?(filter)
          filter_caption(filter).present?
        end

        # The control's accessible name, which is not the caption: with no caption the
        # control still has to name itself or the screen reader announces a bare "combo box"
        # (#1155, WCAG 4.1.2).
        #
        # The caption comes FIRST: where there is a visible caption the accessible name has
        # to contain it (WCAG 2.5.3, "Label in Name"), or the speech-input user says out
        # loud the caption they are reading and nothing happens. It is also what the YARD
        # for `aria_label:` has promised since it was written — "where there is one, the
        # caption keeps naming the control and this is ignored" — and what the six branches
        # already did except the presets picker, which with a caption AND `aria_label:`
        # produced two different names for the same group.
        #
        # With no caption `aria_label:` rules, and failing both, the blank option's text,
        # which is the promise `label: false` already had written down and never kept: "a
        # control that already names itself through its blank option". That last step is a
        # SAFETY NET, not the recommendation: it names the control with its own selected
        # value, so a reader of a Spanish app hears the blank option said twice in a row.
        # Better than mute, worse than an `aria_label:`.
        #
        # `blank:` only counts if it is a string: `include_blank: true` is valid in Rails
        # and paints an empty option, so a `blank: true` would name the control "true" —
        # the same bug as the word "false" this change removes from the boolean branch.
        def accessible_filter_name(filter)
          filter_caption(filter) || filter[:aria_label].presence || blank_option_text(filter)
        end

        def blank_option_text(filter)
          filter[:blank] if filter[:blank].is_a?(String) && filter[:blank].present?
        end

        # An `aria-label` on a control a visible `<label for>` ALREADY points at would be a
        # second name saying the same thing: it is emitted only where the caption does not
        # reach. The exception is `slim_select`, which has its own helper because there the
        # caption never reaches.
        def aria_label_for(filter)
          accessible_filter_name(filter) unless captioned?(filter)
        end

        # SlimSelect shrinks the real `<select>` to 1x1 (`bali/slim_select.css`) and draws
        # its own `div[role="combobox"]`, onto which it copies the select's
        # `aria-label`/`aria-labelledby` and nothing else — the `<label for>` does not
        # travel, its `setupLabelHandlers` only wires clicks. Measured in the accessibility
        # tree: a slim_select WITH a caption announced itself as "Combobox", the widget's
        # default. So this is the only branch where the aria is emitted in the captioned
        # case too, and the only one that points at the caption with `aria-labelledby`
        # instead of repeating the text.
        def slim_select_aria(filter)
          return { "aria-labelledby": filter_label_id(filter) } if captioned?(filter)

          name = accessible_filter_name(filter)
          name.present? ? { "aria-label": name } : {}
        end

        # The period select always has something to fall back on: `blank:`, and if the
        # filter does not declare it, the same string that already names its blank option
        # ("Cualquier fecha").
        def preset_select_accessible_name(filter)
          accessible_filter_name(filter).presence || preset_blank_label(filter)
        end

        # The "Personalizado…" picker is a SECOND control of the same group and never has a
        # `<label for>` of its own — the caption points at the select — so its `aria-label`
        # is always emitted. What it must NOT do is inherit the select's fallback: that text
        # says "Cualquier fecha" and the user opens this field precisely to say the
        # opposite, so the name came out backwards from the function (review of #1155). With
        # neither caption nor `aria_label:` it is named for what it is.
        def preset_picker_accessible_name(filter)
          filter_caption(filter) || filter[:aria_label].presence ||
            t("bali_view.simple_filters.presets.custom_range")
        end

        # A caption over several controls names the GROUP, not one of them. With no caption
        # the group keeps the resolved accessible name; with neither of the two there is no
        # name to put and the `role` on its own adds nothing.
        def group_attributes(filter)
          return {} unless multi_control?(filter)
          return { role: "group", "aria-labelledby": filter_label_id(filter) } if captioned?(filter)

          name = accessible_filter_name(filter)
          name.present? ? { role: "group", "aria-label": name } : {}
        end

        # A filter whose caption cannot be a `<label for>` because it has no
        # single control to point at. Those get a `role="group"` named by the
        # caption instead, which is what a caption over several controls is.
        def multi_control?(filter)
          toggle_group?(filter) || radio_group?(filter) || number_range?(filter)
        end

        # Controls that filter on change instead of waiting for the Filter button:
        # the pills and the native select (#996), where a change event is a
        # completed choice. Restricted here as well as in the DSL, because the
        # instance-level `simple_filters:` hashes come in unvalidated.
        def auto_submit?(filter)
          return false unless filter[:auto_submit]

          toggle_group?(filter) || radio_group?(filter) || select?(filter)
        end

        def any_auto_submit?
          @filters.any? { |filter| auto_submit?(filter) }
        end

        # `submit-on-change` is only mounted when a filter asked for it, so a row
        # without pills keeps the exact markup it had.
        def form_data_attributes
          data = { turbo_frame: "_top" }
          data[:controller] = "submit-on-change" if any_auto_submit?
          data
        end

        # `#submit` and not `#debouncedSubmit`: a pill click or a select choice is a
        # finished choice, and the phantom submit that immediacy used to risk is what
        # the controller's own connect guard now absorbs.
        #
        # `change->` spelled out because Stimulus's default event for an `<input>` is
        # `input`, not `change`. Both fire on a checkbox or radio click, so the two
        # behave the same there — but the one that reads right is the one written,
        # and on a `<select>` it is also the one that fires once per selection.
        def auto_submit_attributes(filter)
          return {} unless auto_submit?(filter)

          { data: { action: "change->submit-on-change#submit" } }
        end

        # Derived from the Ransack param name, not from the attribute: the
        # predicate is what tells two filters over the same column apart, and it
        # is already assumed unique — two filters sharing a name would be
        # fighting over the same param anyway.
        def filter_control_id(filter)
          "simple-filter-#{filter_field_name(filter).gsub(/[^a-zA-Z0-9_-]+/, "-").squeeze("-").delete_suffix("-")}"
        end

        def filter_label_id(filter)
          "#{filter_control_id(filter)}-label"
        end

        def search_input_id
          "simple-filter-search-#{search_field_name.gsub(/[^a-zA-Z0-9_-]+/, "-").squeeze("-").delete_suffix("-")}"
        end

        # Documented since the component was written but never rendered, which
        # left the search box named by its placeholder alone.
        def search_label
          @search.label
        end

        def icon_addon(icon_name)
          return unless icon_name

          tag.div(class: "join-item btn btn-sm btn-disabled no-animation border-base-content/20 bg-base-200 text-base-content/60 px-2.5") do
            render Bali::Icon::Component.new(icon_name, class: "w-4 h-4")
          end
        end

        # With no declared filters the button filters nothing: the only thing it submits is
        # the search term, and "Filtrar" names something that screen does not have. The
        # string for that case was already in the package — `filters.submit_search`, used
        # today as the `aria-label` of the full panel's search box — so it adds no
        # translations.
        def apply_button_text
          return I18n.t("bali_view.filters.submit_search") if @filters.blank?

          I18n.t("bali_view.simple_filters.apply")
        end

        def clear_button_text
          I18n.t("bali_view.simple_filters.clear")
        end

        # Navigating to the bare URL does NOT clear: to the server it is indistinguishable
        # from "no filter came in", and with persistence on that is exactly the case that
        # RESTORES what was saved — the user cleared and the listing handed the filter back.
        # `clear_filters` is the only thing that triggers the cache deletion (`FilterForm`:
        # `Rails.cache.delete`). The other two clearing routes already sent it
        # (`AppliedTags#clear_all_url` and the JS's `clearFiltersAndClose`); this one had
        # been left out.
        #
        # It is ADDED to the query string instead of replacing it: the listing's `url:` can
        # carry the host's own params (`request.fullpath`, a scope), and losing them on
        # clear would send the user to another view.
        #
        # And it drags along the SAME pairs the submit emits as hidden fields
        # (`preserved_query_params`): clearing removes the filters, not the view's state.
        # Without this the link threw away the grouping, the display mode and the host's
        # `preserved_params:` that the submit next to it had just preserved — the panel
        # already did it this way (`clearFiltersAndClose` re-reads the hidden fields).
        def clear_href
          preserved_query_params.reduce(add_query_param(@url, :clear_filters, true)) do |url, (name, value)|
            add_query_param(url, name, value)
          end
        end

        def before_render
          warn_unnamed_filters
        end

        private

        # A filter with no caption, no `aria_label:` and no `blank:` to fall back on has no
        # possible name: `boolean`, `toggle_group`, `radio_group`, `number_range` and the
        # two date ones have no blank option to take it from.
        #
        # It does not blow up. The issue asked for an `ArgumentError`, and that would break
        # a host in production — and the repo's own `UncaptionedSimpleFilterForm` — over an
        # accessibility defect that does not stop the screen from being used. It warns where
        # it can be fixed and carries on, like `AppLayout#check_sidebar_sync!`.
        #
        # And unlike the persistence warning (#1029, development only) this one sounds in
        # test too: that one described a configuration that is only wrong in the host's
        # environment, this one describes markup that comes out just as mute in all three.
        # Once per control and per process, so a host's suite is not filled with the same
        # line.
        def warn_unnamed_filters
          return unless Rails.env.development? || Rails.env.test?

          @filters.each do |filter|
            next if filter_has_a_name?(filter)

            key = filter_control_id(filter)
            next if (self.class.unnamed_filter_warnings_issued ||= Set.new).include?(key)

            self.class.unnamed_filter_warnings_issued << key
            Rails.logger.warn(unnamed_filter_message(filter))
          end
        end

        # Two texts, because what is missing is not the same in the two shapes. In a
        # single-control filter the anonymous thing IS the control. In the multi-control
        # ones — the pills and the number range — each control names itself (its option, or
        # "Mín"/"Máx" from the placeholder) and what is missing is the GROUP's name: without
        # it not even the `role="group"` is emitted, so nothing says which filter those
        # controls belong to. Telling a host that its number range "comes out unnamed" sends
        # them off to fix markup that is already right (review of #1155).
        def unnamed_filter_message(filter)
          detail =
            if multi_control?(filter)
              "the filter renders as several controls that name themselves — each pill its " \
                "own option, each half of a range its placeholder — but nothing names the " \
                "GROUP they belong to, so no `role=\"group\"` is emitted and a screen reader " \
                "never says which filter the user is inside"
            else
              "the control renders with no accessible name, so a screen reader announces it " \
                "unnamed"
            end

          "[Bali] SimpleFilters \"#{filter[:attribute]}\": no caption, no `aria_label:` and " \
            "no `blank:` text to fall back on — #{detail} (WCAG 4.1.2). Pass `aria_label:` " \
            "on the filter, or give it a caption."
        end

        # `presets` always has a name: `preset_blank_label` falls back to a translated
        # string.
        def filter_has_a_name?(filter)
          presets?(filter) || accessible_filter_name(filter).present?
        end

        class << self
          attr_accessor :unnamed_filter_warnings_issued
        end
      end
    end
  end
end
