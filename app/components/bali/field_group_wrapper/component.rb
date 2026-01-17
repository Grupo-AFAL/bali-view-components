# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'form-control w-full'
      LABEL_CLASSES = 'label'
      LABEL_TEXT_CLASSES = 'label-text flex items-center gap-2'

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
        tag.div(id: field_id, class: wrapper_classes, data: @field_data) do
          safe_join([label_html, content].compact)
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

      def label_html
        return if hidden_field? || label_disabled?
        return simple_label if @label_options[:tooltip].blank?

        label_with_tooltip
      end

      def simple_label
        @form.label(@method, @label_options[:text], class: LABEL_CLASSES)
      end

      def label_with_tooltip
        @form.label(@method, class: label_classes) do |translation|
          tag.span(class: LABEL_TEXT_CLASSES) do
            safe_join([
                        @label_options[:text] || translation,
                        tooltip_icon
                      ])
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

      def label_classes
        class_names(LABEL_CLASSES, @label_options[:class])
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
