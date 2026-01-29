# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SlimSelectFields
      WRAPPER_CLASS = 'slim-select'
      SELECT_CLASS = 'select select-bordered'
      TOGGLE_BUTTON_CLASS = 'ss-toggle-btn'

      DEFAULT_OPTIONS = {
        add_items: false,
        show_content: 'auto',
        show_search: true,
        add_to_body: false,
        close_on_select: true,
        allow_deselect_option: false,
        select_all: false,
        disabled: false,
        hide_selected: false,
        search_highlight: false
      }.freeze

      def slim_select_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          slim_select_field(method, values, options, html_options)
        end
      end

      def slim_select_field(method, values, options = {}, html_options = {})
        merged_options = build_options(options)
        merged_html = build_html_options(html_options)

        select_class = merged_html.delete(:select_class)
        custom_class = merged_html[:class]
        merged_html[:class] = class_names([SELECT_CLASS, custom_class].compact)

        field = build_wrapper(method, merged_options, merged_html, select_class) do
          build_select_content(method, values, merged_options, merged_html)
        end

        field_helper(method, field, merged_html)
      end

      private

      def build_options(options)
        DEFAULT_OPTIONS.merge(options).merge(
          search_placeholder: options.fetch(:search_placeholder) do
            I18n.t('bali.form_builder.slim_select.search_placeholder')
          end,
          select_all_text: options.fetch(:select_all_text) do
            I18n.t('bali.form_builder.slim_select.select_all')
          end,
          deselect_all_text: options.fetch(:deselect_all_text) do
            I18n.t('bali.form_builder.slim_select.deselect_all')
          end,
          no_results_text: options.fetch(:no_results_text) do
            I18n.t('bali.form_builder.slim_select.no_results')
          end,
          searching_text: options.fetch(:searching_text) do
            I18n.t('bali.form_builder.slim_select.searching')
          end,
          results_text: options.fetch(:results_text) do
            I18n.t('bali.form_builder.slim_select.results')
          end
        )
      end

      def build_html_options(html_options)
        default_data = { slim_select_target: 'select' }
        user_data = html_options[:data] || {}

        { multiple: false, data: default_data.merge(user_data) }.merge(html_options.except(:data))
      end

      def build_wrapper(method, options, html_options, select_class, &)
        content_tag(:div, wrapper_attributes(method, options, html_options, select_class), &)
      end

      def build_select_content(method, values, options, html_options)
        select_element = select(method, values, options, html_options)

        if options[:select_all]
          select_all_buttons(options) + select_element
        else
          select_element
        end
      end

      def select_all_buttons(options)
        toggle_button(action: 'slim-select#selectAll', target: 'selectAllButton',
                      text: options[:select_all_text]) +
          toggle_button(action: 'slim-select#deselectAll', target: 'deselectAllButton',
                        text: options[:deselect_all_text], hidden: true)
      end

      def toggle_button(action:, target:, text:, hidden: false)
        tag.a(text,
              class: class_names(TOGGLE_BUTTON_CLASS, 'hidden' => hidden),
              data: { action: action, slim_select_target: target })
      end

      def wrapper_attributes(method, options, html_options, select_class)
        {
          id: "#{method}_select_div",
          class: class_names([WRAPPER_CLASS, select_class].compact),
          data: stimulus_data(options, html_options)
        }
      end

      def stimulus_data(options, html_options)
        data = {
          controller: 'slim-select',
          slim_select_placeholder_value: html_options[:placeholder],
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
          slim_select_after_change_fetch_method_value: options[:after_change_fetch_method]
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
