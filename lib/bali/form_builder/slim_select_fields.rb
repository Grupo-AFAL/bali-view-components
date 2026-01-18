# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SlimSelectFields
      WRAPPER_CLASS = 'slim-select'
      SELECT_CLASS = 'select select-bordered'
      BUTTON_CLASS = 'btn btn-sm'

      DEFAULT_OPTIONS = {
        add_items: false,
        show_content: 'auto',
        show_search: true,
        add_to_body: false,
        close_on_select: true,
        allow_deselect_option: false,
        select_all: false
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
          end
        )
      end

      def build_html_options(html_options)
        { multiple: false, 'data-slim-select-target': 'select' }.merge(html_options)
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
              class: class_names(BUTTON_CLASS, 'hidden' => hidden),
              data: { action: action, 'slim-select-target': target })
      end

      def wrapper_attributes(method, options, html_options, select_class)
        {
          id: "#{method}_select_div",
          class: class_names([WRAPPER_CLASS, select_class].compact),
          data: stimulus_data(options, html_options)
        }
      end

      def stimulus_data(options, html_options)
        {
          controller: 'slim-select',
          'slim-select-close-on-select-value': options[:close_on_select],
          'slim-select-allow-deselect-option-value': options[:allow_deselect_option],
          'slim-select-placeholder-value': html_options[:placeholder],
          'slim-select-add-items-value': options[:add_items],
          'slim-select-show-content-value': options[:show_content],
          'slim-select-show-search-value': options[:show_search],
          'slim-select-search-placeholder-value': options[:search_placeholder],
          'slim-select-add-to-body-value': options[:add_to_body],
          'slim-select-select-all-text-value': options[:select_all_text],
          'slim-select-deselect-all-text-value': options[:deselect_all_text],
          'slim-select-ajax-param-name-value': options[:ajax_param_name],
          'slim-select-ajax-value-name-value': options[:ajax_value_name],
          'slim-select-ajax-text-name-value': options[:ajax_text_name],
          'slim-select-ajax-url-value': options[:ajax_url],
          'slim-select-ajax-placeholder-value': options[:ajax_placeholder],
          'slim-select-after-change-fetch-url-value': options[:after_change_fetch_url],
          'slim-select-after-change-fetch-method-value': options[:after_change_fetch_method]
        }
      end
    end
  end
end
