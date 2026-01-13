# frozen_string_literal: true

module Bali
  module Rate
    class Component < ApplicationViewComponent
      attr_reader :form, :method, :value, :scale, :size, :auto_submit, :options

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        value:,
        form: nil,
        method: nil,
        scale: 1..5,
        size: :medium,
        auto_submit: false,
        readonly: false,
        **options
      )
        @value = value
        @form = form
        @method = method
        @scale = scale
        @size = size
        @auto_submit = auto_submit
        @readonly = readonly

        @options = prepend_class_name(options, rate_classes)
        @options = prepend_controller(@options, 'rate')

        @radio_options = options.delete(:radio) || {}
        @radio_options = prepend_data_attribute(@radio_options, 'rate-target', 'star')
        @radio_options = prepend_action(@radio_options, 'rate#submit')
      end
      # rubocop:enable Metrics/ParameterLists

      def readonly?
        @readonly
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

      ICON_SIZES = {
        small: 'size-4',
        medium: 'size-6',
        large: 'size-8'
      }.freeze

      ICON_MARGINS = {
        small: 'mr-1',
        medium: 'mr-2',
        large: 'mr-3'
      }.freeze

      private

      def rate_classes
        class_names(
          'rate-component flex flex-wrap',
          "[&_input[type='radio']]:hidden",
          '[&_.radio+.radio]:ml-0',
          "[&_.icon_path]:fill-base-100 [&_.icon_path]:stroke-warning/80 [&_.icon_path]:[stroke-width:30]",
          '[&_.icon.solid_path]:fill-warning',
          '[&_button.star]:border-none [&_button.star]:bg-transparent [&_button.star]:cursor-pointer [&_button.star]:p-0',
          "[&_label:last-child_.icon]:mr-0 [&_button:last-child_.icon]:mr-0 [&>.icon:last-child]:mr-0"
        )
      end

      def icon_class(rate)
        class_names(ICON_SIZES[size], ICON_MARGINS[size], solid: value.to_i >= rate)
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
