# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SlimSelectFields
      WRAPPER_CLASS = "slim-select"
      SELECT_CLASS = "select select-bordered"
      TOGGLE_BUTTON_CLASS = "ss-toggle-btn"
      SIZE_CLASSES = { sm: "slim-select-sm" }.freeze

      DEFAULT_OPTIONS = {
        add_items: false,
        show_content: "auto",
        show_search: true,
        add_to_body: false,
        close_on_select: true,
        allow_deselect_option: false,
        select_all: false,
        disabled: false,
        hide_selected: false,
        search_highlight: false,
        content_width: nil
      }.freeze

      # Same split as SelectFields: `**options` are the field's own — SlimSelect's
      # behaviour flags and the group's caption — and `html:` is what lands on the
      # `<select>` element.
      def slim_select_group(method, values, *legacy, html: {}, **options)
        options, html = legacy_option_hashes(:slim_select_group, legacy, html, options)
        group = group_options(options, html)

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, group) do
          slim_select_field(method, values, html: html, **options)
        end
      end

      def slim_select_field(method, values, *legacy, html: {}, **options)
        options, html_options = legacy_option_hashes(:slim_select_field, legacy, html, options)
        merged_html = apply_input_name_options(options, build_html_options(html_options))
        merged_options = drop_unenforceable_required(build_options(options), merged_html)
        # `merged_html` carries the real HTML attributes — the Stimulus target
        # among them — so it stays untouched. The caption keys travel separately.
        group = group_options(options, merged_html)

        # `widget_attributes`, not `html_attributes`: this family cannot carry `required`.
        # See #drop_unenforceable_required.
        attributes = widget_attributes(merged_html)
        attributes[:class] = field_class_name(
          method, class_names([ SELECT_CLASS, merged_html[:class] ].compact),
          error_class: "select-error", options: group
        )
        merge_aria_attributes(attributes, method, group)

        field = build_wrapper(method, merged_options, attributes, merged_html[:select_class]) do
          build_select_content(method, values, merged_options, attributes)
        end

        field_helper(method, field, group)
      end

      private

      # `required` on this family is a constraint the user can never be told about, so it is
      # not emitted at all.
      #
      # The `<select>` SlimSelect wraps is clipped to 1x1 by `bali/slim_select.css`, which is
      # correct — SlimSelect draws its own UI — but the browser cannot anchor a validation
      # bubble to a box that size. Measured with only that field invalid:
      # `form.reportValidity()` returns false and focuses the `<select>` (it is focusable,
      # being clipped rather than `display: none`), and NO bubble appears and nothing
      # scrolls. The submit is blocked and there is no way for the user to find out why.
      #
      # {BaliFormBuilderRequiredOptionTest} already writes the contract this settles: the
      # attribute reaches a control the browser validates, or it reaches nothing at all.
      # Being validated but unable to report is the in-between that test exists to forbid.
      #
      # Both hashes have to be stripped, not just the element's: Rails' `select_content_tag`
      # copies `:required`, `:multiple` and `:size` OUT of the select options and onto the
      # element when the element does not already carry them, so a top-level `required:`
      # reaches the `<select>` just as `html: { required: true }` does.
      #
      # The blank option goes back explicitly, because Rails was adding one *as a
      # consequence* of the field being required (`placeholder_required?`). Dropping the
      # attribute silently dropped the blank too, and a nil value then paints as the first
      # option in the list — a record with no priority opening its form with "Low" already
      # chosen. The condition mirrors Rails' own, so nothing changes for a caller who
      # already asked for a blank or a prompt, or for a multiple select (which Rails never
      # gave a blank to anyway).
      def drop_unenforceable_required(options, html_options)
        return options unless options[:required] || html_options[:required]

        if !html_options[:multiple] && options[:include_blank].nil? && options[:prompt].nil?
          options = options.merge(include_blank: true)
        end

        options.except(:required)
      end

      def build_options(options)
        DEFAULT_OPTIONS.merge(options).merge(
          placeholder: options.fetch(:placeholder) do
            I18n.t("bali_view.form_builder.slim_select.placeholder")
          end,
          search_placeholder: options.fetch(:search_placeholder) do
            I18n.t("bali_view.form_builder.slim_select.search_placeholder")
          end,
          select_all_text: options.fetch(:select_all_text) do
            I18n.t("bali_view.form_builder.slim_select.select_all")
          end,
          deselect_all_text: options.fetch(:deselect_all_text) do
            I18n.t("bali_view.form_builder.slim_select.deselect_all")
          end,
          no_results_text: options.fetch(:no_results_text) do
            I18n.t("bali_view.form_builder.slim_select.no_results")
          end,
          searching_text: options.fetch(:searching_text) do
            I18n.t("bali_view.form_builder.slim_select.searching")
          end,
          results_text: options.fetch(:results_text) do
            I18n.t("bali_view.form_builder.slim_select.results")
          end
        )
      end

      def build_html_options(html_options)
        default_data = { slim_select_target: "select" }
        user_data = html_options[:data] || {}

        { multiple: false, data: default_data.merge(user_data) }.merge(html_options.except(:data))
      end

      def build_wrapper(method, options, html_options, select_class, &)
        content_tag(:div, wrapper_attributes(method, options, html_options, select_class), &)
      end

      def build_select_content(method, values, options, html_options)
        select_element = build_select(method, values, options, html_options)

        if options[:select_all]
          select_all_buttons(options) + select_element
        else
          select_element
        end
      end

      # Rails' include_blank / prompt emit a plain empty <option>. SlimSelect only
      # treats an <option> as a placeholder — rendered muted and excluded from the
      # selectable list — when it carries data-placeholder="true"; otherwise it shows
      # the blank as a real, checkmarked, selectable row. When a blank is requested
      # for a flat option list, promote it to a proper SlimSelect placeholder so the
      # "choose one" hint behaves like a placeholder instead of a pickable value.
      def build_select(method, values, options, html_options)
        text = placeholder_option_text(options)
        return select(method, values, options, html_options) if text.nil? || !flat_choices?(values)

        values = [ [ text, "", { data: { placeholder: true } } ], *values ]
        select(method, values, options.except(:include_blank, :prompt), html_options)
      end

      # Rails' select decides between options_for_select and grouped_options_for_select
      # by looking ONLY at the first element (Tags::Select#grouped_choices?). Prepending
      # a flat placeholder to a grouped list flips that detection and mangles every
      # optgroup, so grouped lists keep Rails' plain include_blank behavior instead.
      def flat_choices?(values)
        return false unless values.is_a?(Array)

        first = values.first
        !(first.respond_to?(:last) && first.last.is_a?(Array))
      end

      def placeholder_option_text(options)
        if options[:include_blank]
          options[:include_blank] == true ? "" : options[:include_blank].to_s
        elsif options[:prompt].is_a?(String)
          options[:prompt]
        end
      end

      def select_all_buttons(options)
        toggle_button(action: "slim-select#selectAll", target: "selectAllButton",
                      text: options[:select_all_text]) +
          toggle_button(action: "slim-select#deselectAll", target: "deselectAllButton",
                        text: options[:deselect_all_text], hidden: true)
      end

      def toggle_button(action:, target:, text:, hidden: false)
        tag.a(text,
              class: class_names(TOGGLE_BUTTON_CLASS, "hidden" => hidden),
              data: { action: action, slim_select_target: target })
      end

      # The wrapper id used to be a bare `#{method}_select_div`, which ignored the
      # object name, the index and any nested-attribute path — so two forms for
      # the same model on one page emitted the very same id twice.
      def wrapper_attributes(method, options, html_options, select_class)
        size_class = SIZE_CLASSES[options[:size]&.to_sym]
        {
          id: field_id(method, "select_div"),
          class: class_names([ WRAPPER_CLASS, size_class, select_class ].compact),
          data: stimulus_data(options, html_options)
        }
      end

      def stimulus_data(options, html_options)
        data = {
          controller: "slim-select",
          # `html: { placeholder: }` keeps priority — call sites that pass it must not
          # change. The translated default only fills the gap where nothing was emitted
          # and the Stimulus controller's English 'Select value' won by omission.
          slim_select_placeholder_value: html_options[:placeholder] || options[:placeholder],
          slim_select_show_content_value: options[:show_content],
          slim_select_search_placeholder_value: options[:search_placeholder],
          slim_select_select_all_text_value: options[:select_all_text],
          slim_select_deselect_all_text_value: options[:deselect_all_text],
          slim_select_no_results_text_value: options[:no_results_text],
          slim_select_searching_text_value: options[:searching_text],
          slim_select_results_text_value: options[:results_text],
          slim_select_ajax_param_name_value: options[:ajax_param_name],
          slim_select_ajax_value_name_value: options[:ajax_value_name],
          slim_select_ajax_text_name_value: options[:ajax_text_name],
          slim_select_ajax_url_value: options[:ajax_url],
          slim_select_ajax_placeholder_value: options[:ajax_placeholder],
          slim_select_after_change_fetch_url_value: options[:after_change_fetch_url],
          slim_select_after_change_fetch_method_value: options[:after_change_fetch_method],
          slim_select_content_width_value: options[:content_width]
        }

        # Boolean values - only include when true to reduce HTML size
        # Stimulus defaults handle false cases
        data[:slim_select_add_items_value] = true if options[:add_items]
        data[:slim_select_add_to_body_value] = true if options[:add_to_body]
        data[:slim_select_allow_deselect_option_value] = true if options[:allow_deselect_option]
        data[:slim_select_disabled_value] = true if options[:disabled]
        data[:slim_select_hide_selected_value] = true if options[:hide_selected]
        data[:slim_select_search_highlight_value] = true if options[:search_highlight]

        # Boolean values with non-false defaults - must be explicit
        data[:slim_select_close_on_select_value] = false if options[:close_on_select] == false
        data[:slim_select_show_search_value] = false if options[:show_search] == false

        data
      end
    end
  end
end
