# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module HtmlUtils
      # Shared class for input addons (currency $, percentage %, etc.)
      ADDON_CLASSES = 'btn btn-disabled pointer-events-none join-item'

      def field_options(method, options)
        pattern_types = {
          number_with_commas: '^(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$'
        }

        pattern_type = options.delete(:pattern_type)
        options[:pattern] = pattern_types[pattern_type] if pattern_type

        # Add join-item class when addons are present for proper DaisyUI join pattern
        has_addons = options[:addon_left].present? || options[:addon_right].present?
        base_class = has_addons ? 'input input-bordered join-item grow' : 'input input-bordered'

        options[:class] = field_class_name(method, "#{base_class} #{options[:class]}")
        options.except(:addon_left, :addon_right)
      end

      def field_helper(method, field, options = {})
        if errors?(method)
          help_message = content_tag(:p, full_errors(method), class: 'label-text-alt text-error')
        elsif options[:help]
          help_message = content_tag(:p, options[:help], class: 'label-text-alt')
        end

        left_addon = options.delete(:addon_left)
        right_addon = options.delete(:addon_right)

        # When addons exist, don't wrap in control div - use join pattern directly
        if left_addon.present? || right_addon.present?
          return field_with_addons(field, left: left_addon, right: right_addon) + help_message
        end

        control_class = ['control', options.delete(:control_class)].compact.join(' ')
        wrapped_field = content_tag(
          :div, field, class: control_class, data: options.delete(:control_data)
        )

        wrapped_field + help_message
      end

      def field_class_name(method, class_name = 'input')
        return class_name unless errors?(method)

        "#{class_name} input-error"
      end

      def errors?(method)
        object.respond_to?(:errors) && object.errors.key?(method)
      end

      def full_errors(method)
        safe_join(object.errors.full_messages_for(method), ', ')
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
        content_tag(:div, class: 'join w-full') do
          @template.safe_join([left, field, right].compact)
        end
      end
    end
  end
end
