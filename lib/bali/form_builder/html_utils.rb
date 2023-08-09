# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module HtmlUtils
      def field_options(method, options)
        pattern_types = {
          number_with_commas: '^(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$'
        }

        pattern_type = options.delete(:pattern_type)
        options[:pattern] = pattern_types[pattern_type] if pattern_type

        options[:class] = field_class_name(method, "input #{options[:class]}")
        options.except(:addon_left, :addon_right)
      end

      def field_helper(method, field, options = {})
        if errors?(method)
          help_message = content_tag(:p, full_errors(method), class: 'help is-danger')
        elsif options[:help]
          help_message = content_tag(:p, options[:help], class: 'help')
        end

        left_addon = options.delete(:addon_left)
        right_addon = options.delete(:addon_right)

        wrapped_field = content_tag(:div, field,
                                    class: "control #{options.delete(:control_class)}",
                                    data: options.delete(:control_data))

        return wrapped_field + help_message if left_addon.blank? && right_addon.blank?

        field_with_addons(wrapped_field, left: left_addon, right: right_addon) + help_message
      end

      def field_class_name(method, class_name = 'input')
        return class_name unless errors?(method)

        "#{class_name} is-danger"
      end

      def errors?(method)
        object.respond_to?(:errors) && object.errors.key?(method)
      end

      def full_errors(method)
        object.errors.full_messages_for(method).join(', ').html_safe
      end

      # rubocop:disable Style/OptionalBooleanParameter
      #
      # This method is just a passthrough for the Rails method, so we can't really change the
      # signature of the method.
      def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &)
        @template.content_tag(name, content_or_options_with_block, options, escape, &)
      end
      # rubocop:enable Style/OptionalBooleanParameter

      # rubocop:disable Metrics/ParameterLists, Style/OptionalBooleanParameter
      def tag(name = nil, options = nil, open = false, escape = true)
        @template.tag(name, options, open, escape)
      end
      # rubocop:enable Metrics/ParameterLists, Style/OptionalBooleanParameter

      def safe_join(array, separator = nil)
        @template.safe_join(array, separator)
      end

      def translate_attribute(method)
        model_name = object.model_name.i18n_key
        I18n.t("activerecord.attributes.#{model_name}.#{method}", default: method.to_s.humanize)
      end

      private

      def field_with_addons(field, left:, right:)
        content_tag(:div, class: 'field has-addons') do
          @template.safe_join(
             [generate_addon_html(left), field, generate_addon_html(right)].compact
           ) 
        end 
      end

      def generate_addon_html(addon_content)
        content_tag(:div, class: 'control') { addon_content } if addon_content.present?
      end
    end
  end
end
