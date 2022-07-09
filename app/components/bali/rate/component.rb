# frozen_string_literal: true

module Bali
  module Rate
    class Component < ApplicationViewComponent
      attr_reader :form, :method, :value, :scale, :size, :auto_submit, :options

      def initialize(form:, method:, value:, scale: 1..5, auto_submit: false, **options)
        @form = form
        @method = method
        @value = value
        @scale = scale
        @auto_submit = auto_submit
        @size = options.delete(:size) || :medium

        @options = prepend_class_name(options, 'rate-component')
        @options = prepend_controller(@options, 'rate')

        @radio_options = options.delete(:radio) || {}
        @radio_options = prepend_data_attribute(@radio_options, 'rate-target', 'star')
        @radio_options = prepend_action(@radio_options, 'rate#submit')
      end

      def input_name
        "#{form_object_class}[#{method}]"
      end

      def star_dom_id(rate)
        "#{form_object_class}_#{rate}_#{unique_identifier}"
      end

      def star_icon(rate)
        render(Bali::Icon::Component.new('star', class: icon_class(rate)))
      end

      private

      def icon_class(rate)
        class_names("is-#{size}", solid: value.to_i >= rate)
      end

      def form_object_class
        dom_class(form.object)
      end

      def unique_identifier
        @unique_identifier ||= DateTime.now.strftime('%Q')
      end
    end
  end
end
