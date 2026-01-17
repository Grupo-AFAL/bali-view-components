# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SlimSelectFields
      def slim_select_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          slim_select_field(method, values, options, html_options)
        end
      end

      def slim_select_field(method, values, options = {}, html_options = {})
        html_options.with_defaults!(multiple: false, 'data-slim-select-target': 'select')

        options.with_defaults!(
          add_items: false,
          show_content: 'auto',
          show_search: true,
          search_placeholder: I18n.t('bali.form_builder.slim_select.search_placeholder'),
          add_to_body: false,
          close_on_select: true,
          allow_deselect_option: false,
          select_all: false,
          select_all_text: I18n.t('bali.form_builder.slim_select.select_all'),
          deselect_all_text: I18n.t('bali.form_builder.slim_select.deselect_all')
        )

        html_options[:class] = ['select select-bordered', html_options[:class]].compact.join(' ')

        field = content_tag(:div, slim_select_field_options(method, html_options, options)) do
          if options[:select_all]
            anchor_button('slim-select#selectAll', 'selectAllButton', options[:select_all_text]) +
              anchor_button('slim-select#deselectAll', 'deselectAllButton',
                            options[:deselect_all_text], 'display: none;') +
              select(method, values, options, html_options)
          else
            select(method, values, options, html_options)
          end
        end

        field_helper(method, field, html_options)
      end

      private

      def anchor_button(action, target, text, style = nil)
        data = { action: action, 'slim-select-target': target }
        tag.a text, class: 'btn btn-sm', style: style, data: data
      end

      def slim_select_field_options(method, html_options, options)
        {
          id: "#{method}_select_div",
          class: "slim-select #{html_options.delete(:select_class)}".strip,
          'data-controller': 'slim-select',
          'data-slim-select-close-on-select-value': options[:close_on_select],
          'data-slim-select-allow-deselect-option-value': options[:allow_deselect_option],
          'data-slim-select-placeholder-value': html_options[:placeholder],
          'data-slim-select-add-items-value': options[:add_items],
          'data-slim-select-show-content-value': options[:show_content],
          'data-slim-select-show-search-value': options[:show_search],
          'data-slim-select-search-placeholder-value': options[:search_placeholder],
          'data-slim-select-add-to-body-value': options[:add_to_body],
          'data-slim-select-select-all-text-value': options[:select_all_text],
          'data-slim-select-deselect-all-text-value': options[:deselect_all_text],
          'data-slim-select-ajax-param-name-value': options[:ajax_param_name],
          'data-slim-select-ajax-value-name-value': options[:ajax_value_name],
          'data-slim-select-ajax-text-name-value': options[:ajax_text_name],
          'data-slim-select-ajax-url-value': options[:ajax_url],
          'data-slim-select-ajax-placeholder-value': options[:ajax_placeholder],
          'data-slim-select-after-change-fetch-url-value': options[:after_change_fetch_url],
          'data-slim-select-after-change-fetch-method-value': options[:after_change_fetch_method]
        }
      end
    end
  end
end
