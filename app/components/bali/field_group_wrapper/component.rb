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

        @addon_left = options.delete(:addon_left)
        @addon_right = options.delete(:addon_right)
        @field_class = options.delete(:field_class)
        @data = options.delete(:field_data)
      end

      def call
        field_id = "field-#{@method}"
        class_name = "field-group-wrapper-component field #{@field_class}"

        content_tag(:div, id: field_id, class: class_name, data: @data) do
          safe_join([generate_label_html, inner_field_div].compact)
        end
      end

      private

      def inner_field_div
        return content if @addon_left.blank? && @addon_right.blank?

        content_tag(:div, class: 'field has-addons') do
          safe_join([addon_left, content, addon_right].compact)
        end
      end

      def addon_left
        generate_addon_html(@addon_left) if @addon_left.present?
      end

      def addon_right
        generate_addon_html(@addon_right) if @addon_right.present?
      end

      def generate_addon_html(addon_content)
        return if addon_content.blank?

        content_tag(:div, class: 'control') do
          addon_content
        end
      end

      def generate_label_html
        return if @options[:type] == 'hidden' || @label_options[:text] == false
        return @form.label(@method, @label_options[:text]) if @label_options[:tooltip].nil?

        @form.label(@method, class: 'label is-flex is-align-items-center') do |translation|
          safe_join([
                      translation || @label_options[:text],
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
