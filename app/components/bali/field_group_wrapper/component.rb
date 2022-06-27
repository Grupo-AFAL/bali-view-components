# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Component < ApplicationViewComponent
      def initialize(form, method, options)
        @form = form
        @method = method
        @options = options

        @label_text = options.delete(:label)
        @addon_left = options.delete(:addon_left)
        @addon_right = options.delete(:addon_right)
        @field_class = options.delete(:field_class)
        @data = options.delete(:field_data)
      end

      def call
        field_id = "field-#{@method}"
        class_name = "field #{@field_class}"
  
        content_tag(:div, id: field_id, class: class_name, data: @data) do
          safe_join([generate_label_html, inner_field_div].compact)
        end
      end

      private

      def inner_field_div
        return content if @addon_left.blank? &&  @addon_right.blank?
  
        content_tag(:div, class: 'field has-addons') do
          safe_join([addon_left, content, addon_right].compact)
        end
      end
  
      def addon_left
        return if @addon_left.blank?
  
        generate_addon_html(@addon_left)
      end
  
      def addon_right
        return if @addon_right.blank?
  
        generate_addon_html(@addon_right)
      end
  
      def generate_addon_html(addon_content)
        return if addon_content.blank?
  
        content_tag(:div, class: 'control') do
          addon_content
        end
      end
  
      def generate_label_html
        @form.label(@method, @label_text) unless @options[:type] == 'hidden' || @label_text == false
      end
    end
  end
end