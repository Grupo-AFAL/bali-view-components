# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Component < ApplicationViewComponent
      def initialize(form, method, options = {})
        @form = form
        @method = method
        @options = options

        @label_options = options.delete(:label)
        @label_options = { text: @label_options } unless @label_options.is_a?(Hash)

        @field_class = options.delete(:field_class)
        @data = options.delete(:field_data)
      end

      def call
        field_id = "field-#{@method}"
        class_name = "field-group-wrapper-component field #{@field_class}"

        content_tag(:div, id: field_id, class: class_name, data: @data) do
          safe_join([generate_label_html, content].compact)
        end
      end

      private

      def generate_label_html
        return if @options[:type] == 'hidden' || @label_options[:text] == false
        return @form.label(@method, @label_options[:text]) if @label_options[:tooltip].nil?

        label_class = @label_options[:class] || 'is-flex is-align-items-center'
        @form.label(@method, class: ['label', label_class].join(' ')) do |translation|
          safe_join([
                      @label_options[:text] || translation,
                      label_tooltip(@label_options[:tooltip])
                    ])
        end
      end

      def label_tooltip(content)
        render(Bali::Tooltip::Component.new) do |c|
          c.trigger { render(Bali::Icon::Component.new('info-circle')) }

          content
        end
      end
    end
  end
end
