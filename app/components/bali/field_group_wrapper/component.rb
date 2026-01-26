# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Component < ApplicationViewComponent
      # DaisyUI 5 uses fieldset pattern for form groups
      BASE_CLASSES = 'fieldset w-full'
      LEGEND_CLASSES = 'fieldset-legend'
      LEGEND_TEXT_CLASSES = 'flex items-center gap-2'

      def initialize(form, method, options = {})
        @form = form
        @method = method
        @label_options = normalize_label_options(options[:label])
        @field_class = options[:field_class]
        @field_data = options[:field_data]
        @type = options[:type]
        @custom_class = options[:class]
      end

      def call
        tag.fieldset(id: field_id, class: wrapper_classes, data: @field_data) do
          safe_join([legend_html, content].compact)
        end
      end

      private

      attr_reader :form, :method, :label_options, :field_class, :field_data, :type

      def field_id
        "field-#{@method}"
      end

      def wrapper_classes
        class_names(BASE_CLASSES, @field_class, @custom_class)
      end

      def legend_html
        return if hidden_field? || label_disabled?
        return simple_legend if @label_options[:tooltip].blank?

        legend_with_tooltip
      end

      def simple_legend
        label_text = @label_options[:text] || @form.translate_attribute(@method)
        tag.legend(label_text, class: LEGEND_CLASSES)
      end

      def legend_with_tooltip
        tag.legend(class: legend_classes) do
          tag.span(class: LEGEND_TEXT_CLASSES) do
            label_text = @label_options[:text] || @form.translate_attribute(@method)
            safe_join([label_text, tooltip_icon])
          end
        end
      end

      def tooltip_icon
        render(Bali::Tooltip::Component.new) do |tooltip|
          tooltip.with_trigger do
            render(Bali::Icon::Component.new('info-circle', class: 'size-4 text-base-content/60'))
          end
          @label_options[:tooltip]
        end
      end

      def legend_classes
        class_names(LEGEND_CLASSES, @label_options[:class])
      end

      def hidden_field?
        @type.to_s == 'hidden'
      end

      def label_disabled?
        @label_options[:text] == false
      end

      def normalize_label_options(label)
        case label
        when Hash then label
        when nil then {}
        else { text: label }
        end
      end
    end
  end
end
