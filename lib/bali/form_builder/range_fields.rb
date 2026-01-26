# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RangeFields
      RANGE_CLASS = 'range'
      FIELDSET_CLASS = 'fieldset'
      LEGEND_CLASS = 'fieldset-legend text-sm font-medium'
      TICKS_CLASS = 'flex justify-between text-xs text-base-content/60 px-0.5 mt-1'

      SIZES = {
        xs: 'range-xs',
        sm: 'range-sm',
        md: 'range-md',
        lg: 'range-lg'
      }.freeze

      COLORS = {
        primary: 'range-primary',
        secondary: 'range-secondary',
        accent: 'range-accent',
        success: 'range-success',
        warning: 'range-warning',
        info: 'range-info',
        error: 'range-error'
      }.freeze

      # Renders a range slider with label, optional tick marks, and value display
      #
      # @param method [Symbol] The attribute name
      # @param options [Hash] Options for the range field
      # @option options [String] :label The label text (defaults to humanized method name)
      # @option options [Numeric] :min Minimum value (default: 0)
      # @option options [Numeric] :max Maximum value (default: 100)
      # @option options [Numeric] :step Step increment (default: 1)
      # @option options [Symbol] :size Size variant (:xs, :sm, :md, :lg)
      # @option options [Symbol] :color Color variant (:primary, :secondary, :accent, etc.)
      # @option options [Boolean] :show_ticks Show tick marks below slider (default: false)
      # @option options [Integer] :ticks Number of tick marks (default: calculated from step)
      # @option options [Array] :tick_labels Custom labels for ticks (overrides auto-generation)
      # @option options [String] :prefix Prefix for tick labels (e.g., '$')
      # @option options [String] :suffix Suffix for tick labels (e.g., '%')
      #
      # @example Basic usage
      #   f.range_field_group :volume, min: 0, max: 100, color: :primary
      #
      # @example With tick marks
      #   f.range_field_group :price, min: 0, max: 1000, step: 100, show_ticks: true, prefix: '$'
      #
      # @example Custom tick labels
      #   f.range_field_group :rating, min: 1, max: 5, tick_labels: %w[Bad Poor OK Good Great]
      #
      def range_field_group(method, options = {})
        label_text = options.delete(:label) || translate_attribute(method)

        # Extract tick options before they're deleted by build_range_options
        tick_options = {
          show_ticks: options[:show_ticks],
          ticks: options[:ticks],
          tick_labels: options[:tick_labels],
          prefix: options[:prefix],
          suffix: options[:suffix],
          min: options[:min] || 0,
          max: options[:max] || 100
        }

        content_tag(:fieldset, class: FIELDSET_CLASS) do
          safe_join([
            content_tag(:legend, label_text, class: LEGEND_CLASS),
            range_field(method, options),
            build_range_ticks(tick_options)
          ].compact)
        end
      end

      # Renders just the range input without wrapper
      def range_field(method, options = {})
        range_options = build_range_options(method, options)
        field_html = @template.range_field(object_name, method, range_options)

        if errors?(method)
          error_html = content_tag(:p, full_errors(method), class: 'label-text-alt text-error mt-1')
          field_html + error_html
        else
          field_html
        end
      end

      private

      def build_range_options(method, options)
        size = options.delete(:size)
        color = options.delete(:color)
        custom_class = options.delete(:class)

        # Extract display options (not passed to input)
        options.delete(:show_ticks)
        options.delete(:ticks)
        options.delete(:tick_labels)
        options.delete(:prefix)
        options.delete(:suffix)

        range_class = [
          RANGE_CLASS,
          'w-full',
          SIZES[size],
          COLORS[color],
          (errors?(method) ? 'range-error' : nil),
          custom_class
        ].compact.join(' ')

        # Set defaults
        options[:min] ||= 0
        options[:max] ||= 100
        options[:step] ||= 1

        options.merge(class: range_class)
      end

      def build_range_ticks(options)
        return nil unless options[:show_ticks] || options[:tick_labels].present?

        labels = resolve_tick_labels(options)

        content_tag(:div, class: TICKS_CLASS) do
          safe_join(labels.map { |label| content_tag(:span, label) })
        end
      end

      def resolve_tick_labels(options)
        return options[:tick_labels] if options[:tick_labels].present?

        min = options[:min] || 0
        max = options[:max] || 100
        step = options[:step] || 1
        ticks_count = options[:ticks] || calculate_ticks_count(min, max, step)

        generate_tick_labels(min, max, ticks_count, options[:prefix] || '', options[:suffix] || '')
      end

      def calculate_ticks_count(min, max, step)
        # Calculate reasonable number of ticks (max 11 for readability)
        range = max - min
        steps = (range / step).to_i
        [steps + 1, 11].min
      end

      def generate_tick_labels(min, max, count, prefix, suffix)
        return ["#{prefix}#{min}#{suffix}", "#{prefix}#{max}#{suffix}"] if count <= 2

        step = (max - min).to_f / (count - 1)
        (0...count).map do |i|
          value = min + (step * i)
          # Format as integer if whole number, otherwise keep decimal
          formatted = value == value.to_i ? value.to_i : value.round(1)
          "#{prefix}#{formatted}#{suffix}"
        end
      end
    end
  end
end
