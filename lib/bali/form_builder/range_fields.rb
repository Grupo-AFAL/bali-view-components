# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RangeFields
      RANGE_CLASS = "range"
      FIELDSET_CLASS = "fieldset"
      LEGEND_CLASS = "fieldset-legend text-sm font-medium"
      TICKS_CLASS = "flex justify-between text-xs text-base-content/60 px-0.5 mt-1"

      # Read by the slider itself: `size` and `color` are daisyUI variants here,
      # and the tick options only ever feed the labels rendered under the input.
      RANGE_OPTIONS = %i[size color show_ticks ticks tick_labels prefix suffix].freeze

      SIZES = {
        xs: "range-xs",
        sm: "range-sm",
        md: "range-md",
        lg: "range-lg"
      }.freeze

      COLORS = {
        primary: "range-primary",
        secondary: "range-secondary",
        accent: "range-accent",
        success: "range-success",
        warning: "range-warning",
        info: "range-info",
        error: "range-error"
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
        label_text = options[:label] || translate_attribute(method)

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
            range_caption(method, label_text, options),
            range_field(method, options),
            build_range_ticks(tick_options)
          ].compact)
        end
      end

      # Renders just the range input without wrapper
      def range_field(method, options = {})
        range_options = build_range_options(method, options)

        @template.range_field(object_name, method, range_options) +
          error_and_help(method, options)
      end

      private

      # This family builds its own fieldset rather than going through
      # FieldGroupWrapper, so it needs the same fix on its own: a `<legend>`
      # names the fieldset, never the slider inside it, which left every range
      # input without an accessible name.
      def range_caption(method, label_text, options)
        content_tag(:label, label_text, class: LEGEND_CLASS,
                                        id: label_id(method), for: control_id(method, options))
      end

      def build_range_options(method, options)
        range_class = [
          RANGE_CLASS,
          "w-full",
          SIZES[options[:size]],
          COLORS[options[:color]],
          (errors?(method) ? "range-error" : nil),
          options[:class]
        ].compact.join(" ")

        attributes = html_attributes(options).except(:class, *RANGE_OPTIONS)

        # Set defaults
        attributes[:min] ||= 0
        attributes[:max] ||= 100
        attributes[:step] ||= 1

        merge_aria_attributes(attributes.merge(class: range_class), method, options)
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

        generate_tick_labels(min, max, ticks_count, options[:prefix] || "", options[:suffix] || "")
      end

      def calculate_ticks_count(min, max, step)
        # Calculate reasonable number of ticks (max 11 for readability)
        range = max - min
        steps = (range / step).to_i
        [ steps + 1, 11 ].min
      end

      def generate_tick_labels(min, max, count, prefix, suffix)
        return [ "#{prefix}#{min}#{suffix}", "#{prefix}#{max}#{suffix}" ] if count <= 2

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
