# frozen_string_literal: true

module Bali
  module Rate
    # Rating component using DaisyUI's native rating classes.
    # Renders star-shaped radio buttons for collecting ratings.
    # Supports form integration, auto-submit, and readonly modes.
    #
    # @example Basic usage with form
    #   <%= render Bali::Rate::Component.new(form: f, method: :rating, value: 3) %>
    #
    # @example Readonly display
    #   <%= render Bali::Rate::Component.new(value: 4, readonly: true) %>
    #
    # @example Auto-submit on click
    #   <%= render Bali::Rate::Component.new(
    #         form: f, method: :rating, value: 2, auto_submit: true
    #       ) %>
    #
    class Component < ApplicationViewComponent
      SIZES = {
        xs: 'rating-xs',
        sm: 'rating-sm',
        md: 'rating-md',
        lg: 'rating-lg'
      }.freeze

      COLORS = {
        warning: 'bg-warning',
        primary: 'bg-primary',
        secondary: 'bg-secondary',
        accent: 'bg-accent',
        success: 'bg-success',
        error: 'bg-error',
        info: 'bg-info'
      }.freeze

      attr_reader :value, :scale, :size, :color, :form, :method

      # rubocop:disable Metrics/ParameterLists
      def initialize(value:, form: nil, method: nil, scale: 1..5, size: :md,
                     color: :warning, auto_submit: false, readonly: false, **options)
        @value = value.to_i
        @form = form
        @method = method
        @scale = scale
        @size = size
        @color = color
        @auto_submit = auto_submit
        @readonly = readonly
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def auto_submit? = @auto_submit
      def readonly? = @readonly

      def input_name
        "#{dom_class(form.object)}[#{method}]"
      end

      def star_id(rate)
        "#{dom_class(form.object)}_#{method}_#{rate}"
      end

      def star_aria_label(rate)
        t('.star_rating', number: rate)
      end

      def rating_label
        t('.label')
      end

      private

      def rating_classes
        class_names(
          'rating',
          SIZES[size],
          @options[:class]
        )
      end

      def star_classes
        class_names(
          'mask mask-star-2',
          COLORS[color]
        )
      end

      def container_attributes
        base_attrs = @options.except(:class).merge(class: rating_classes)
        base_attrs[:role] = 'radiogroup' unless readonly?
        base_attrs[:'aria-label'] = @options[:'aria-label'] || rating_label
        base_attrs[:data] = { controller: 'rate', rate_auto_submit_value: true } if auto_submit?
        base_attrs
      end
    end
  end
end
