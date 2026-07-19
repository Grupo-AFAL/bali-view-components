# frozen_string_literal: true

module Bali
  module Status
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      CONTROLLER = "status"

      # Fixed, vibrant status palette. Rendered as inline styles (never Tailwind
      # bg-* classes) so statuses look identical across DaisyUI themes and need
      # no safelist. `fg` values are picked for AA-ish contrast on `bg`.
      PALETTE = {
        slate:  { bg: "#64748b", fg: "#fff" },
        gray:   { bg: "#d1d5db", fg: "#1f2937" },
        red:    { bg: "#dc2626", fg: "#fff" },
        orange: { bg: "#ea580c", fg: "#fff" },
        amber:  { bg: "#f59e0b", fg: "#1f2937" },
        yellow: { bg: "#eab308", fg: "#1f2937" },
        green:  { bg: "#16a34a", fg: "#fff" },
        teal:   { bg: "#0d9488", fg: "#fff" },
        blue:   { bg: "#2563eb", fg: "#fff" },
        indigo: { bg: "#4f46e5", fg: "#fff" },
        violet: { bg: "#6d28d9", fg: "#fff" },
        pink:   { bg: "#db2777", fg: "#fff" }
      }.freeze

      SIZES = { xs: "status--xs", sm: "status--sm", md: "status--md" }.freeze

      DEFAULT_COLOR = :slate

      def initialize(selected: nil, options: [], form: nil, readonly: false,
                     clearable: false, size: :sm, placeholder: nil, **html_options)
        @selected = selected.presence&.to_s
        @options = options
        @form = form
        @readonly = readonly
        @clearable = clearable
        @size = size&.to_sym
        @placeholder = placeholder
        @html_options = html_options
      end

      private

      attr_reader :options, :form, :clearable, :html_options

      def editable?
        form.present? && !@readonly
      end

      def clearable?
        editable? && clearable
      end

      def selected?
        @selected.present?
      end

      def selected_option
        @selected_option ||= options.find { |o| o[:value].to_s == @selected }
      end

      def selected_label
        return placeholder unless selected?

        selected_option&.dig(:label) || @selected
      end

      def placeholder
        @placeholder.presence || t("bali.status.no_status", default: "No status")
      end

      def param
        form[:param]
      end

      def form_method
        form.fetch(:method, :patch)
      end

      # Resolves a palette symbol or a hex string to { bg:, fg: } for inline styling.
      def resolve_color(color)
        return PALETTE.fetch(DEFAULT_COLOR) if color.blank?

        if color.is_a?(Symbol) || PALETTE.key?(color.to_s.to_sym)
          PALETTE.fetch(color.to_sym, PALETTE.fetch(DEFAULT_COLOR))
        else
          { bg: color, fg: contrasting_text_color(color) }
        end
      end

      def pill_style(color)
        c = resolve_color(color)
        "background-color: #{c[:bg]}; color: #{c[:fg]};"
      end

      def selected_style
        return if @selected.blank?

        pill_style(selected_option&.dig(:color))
      end

      def size_class
        SIZES.fetch(@size, SIZES[:sm])
      end

      def pill_classes(extra = nil)
        class_names("status-pill", size_class, extra, "status-pill--none" => !selected?)
      end

      def container_classes
        class_names("status-component", "inline-block", html_options[:class])
      end

      def container_attributes
        attrs = html_options.except(:class)
        attrs[:class] = container_classes
        attrs[:data] = attrs[:data].dup if attrs[:data]
        prepend_controller(attrs, CONTROLLER) if editable?
        attrs
      end
    end
  end
end
