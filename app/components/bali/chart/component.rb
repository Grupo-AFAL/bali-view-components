# frozen_string_literal: true

# Data input formats:
#   Format 1 (simple hash):
#     { "Mon" => 10, "Tue" => 20, "Wed" => 30 }
#     where: key is x-axis label, value is y-axis value
#
#   Format 2 (multi-series):
#     {
#       labels: ["Wed, 12 Jan 2022", "Thu, 13 Jan 2022"],
#       datasets: [{ label: "Beef", data: [10, 5] }, { label: "Pork", data: [20, 10] }]
#     }
#     where: labels are x-axis labels, each dataset has its own label and data array

module Bali
  module Chart
    # rubocop:disable Metrics/ClassLength
    class Component < ApplicationViewComponent
      MAX_LABEL_LENGTH = 16
      MULTI_COLOR_TYPES = %i[pie doughnut polarArea].freeze
      BAR_TYPES = %i[bar].freeze

      # System font stack matching DaisyUI/Tailwind
      FONT_FAMILY = 'ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"'

      DEFAULT_OPTIONS = {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 800,
          easing: "easeOutQuart"
        }
      }.freeze

      # Card style variants
      CARD_STYLES = {
        default: "card bg-base-100 shadow-sm",
        bordered: "card bg-base-100 card-border",
        compact: "card bg-base-100 card-compact shadow-sm",
        none: "" # No card wrapper
      }.freeze

      # Chart height presets
      HEIGHTS = {
        sm: "h-[180px]",
        md: "h-[250px]",
        lg: "h-[350px]",
        xl: "h-[450px]"
      }.freeze

      # A canvas is opaque to assistive tech: whatever Chart.js paints into it is
      # pixels, and the fallback content inside the tag is only surfaced when
      # canvas itself is unsupported. `role="img"` plus a name is the least a
      # chart owes; the `data_table` slot is the version a screen reader can
      # actually read a number out of.
      renders_one :data_table

      attr_reader :title

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        type: :bar,
        data: {},
        title: nil,
        aria_label: nil,
        legend: false,
        display_percent: false,
        order: [],
        y_axis_ids: [],
        options: {},
        card_style: :none,
        height: :md,
        use_theme_colors: true,
        color: nil,
        custom_color: nil,
        **html_options
      )
        # rubocop:enable Metrics/ParameterLists
        @types = Array.wrap(type)
        # Every lookup below is by Symbol (`@data[:labels]`, `@data[:datasets]`), and
        # each dataset hash is splatted into Dataset's keyword arguments. A host
        # handing over string keys — anything that round-tripped through JSON — used
        # to fall through to the simple `{ label => value }` branch and silently
        # chart the *words* "labels" and "datasets" as its two categories.
        @data = data.deep_symbolize_keys
        @title = title
        @aria_label = aria_label
        @display_percent = display_percent
        @order = order
        @y_axis_ids = y_axis_ids
        @card_style = card_style.to_sym
        @height = height.to_sym
        @use_theme_colors = use_theme_colors
        @custom_color = Bali::Color.hex!(self.class, custom_color)
        @color = Bali::Color.name!(self.class, color)
        @options = build_options(options, legend)
        @html_options = html_options
        @color_picker = Bali::Utils::ColorPicker.new(
          use_theme_colors: use_theme_colors, color: @color, custom_color: @custom_color
        )
      end

      def chart_type
        @types.first
      end

      def chart_data_json
        { labels: truncated_labels, datasets: datasets }.to_json
      end

      def labels_json
        labels.to_json
      end

      def options_json
        @options.to_json
      end

      def display_percent?
        @display_percent
      end

      def card_classes
        CARD_STYLES[@card_style]
      end

      def render_card?
        @card_style != :none
      end

      def container_classes
        class_names(
          "chart-container",
          HEIGHTS[@height] || HEIGHTS[:md],
          @html_options[:class]
        )
      end

      def container_options
        @html_options.except(:class)
      end

      # The title is already the chart's name on screen, so it is also its name
      # in the accessibility tree. A chart with neither title nor `aria_label:`
      # still gets a name — an unnamed `role="img"` is worse than a generic one.
      def aria_label
        @aria_label || title.presence || I18n.t("bali_view.chart.default_label")
      end

      def canvas_attributes
        {
          class: "chart",
          role: "img",
          "aria-label": aria_label,
          data: {
            controller: "chart",
            chart_type_value: chart_type,
            chart_data_value: chart_data_json,
            chart_labels_value: labels_json,
            chart_options_value: options_json,
            chart_display_percent_value: display_percent?,
            chart_use_theme_colors_value: use_theme_colors?,
            chart_color_value: theme_color_variable
          }
        }
      end

      def use_theme_colors?
        @use_theme_colors
      end

      # The controller recomputes every theme colour in the browser (a canvas
      # cannot resolve a `var()`), so it needs the same rotation Ruby applied or
      # it hands the first dataset `--color-primary` again.
      def theme_color_variable
        Bali::Color.variable_name(@color)
      end

      private

      def build_options(custom_options, legend)
        base_opts = DEFAULT_OPTIONS.deep_dup
        configure_legend(base_opts, legend)
        configure_theme_styling(base_opts) if @use_theme_colors

        # Same normalization `data:` gets in the initializer: every key Bali
        # writes below is a Symbol, so a String-keyed `options:` would sit NEXT
        # to the theme styling instead of merging with it — duplicate keys in
        # the JSON (an error under json 3.0), and the browser keeping only
        # whichever entry came last (#1066).
        base_opts.deep_merge(custom_options.deep_symbolize_keys)
      end

      def configure_legend(opts, display)
        opts[:plugins] ||= {}
        opts[:plugins][:legend] ||= {}
        opts[:plugins][:legend][:display] = display
        opts[:plugins][:legend][:labels] ||= {}
        # Use theme-aware text color for legend
        opts[:plugins][:legend][:labels][:useThemeColors] = @use_theme_colors
      end

      def configure_theme_styling(opts)
        configure_scales_styling(opts)
        configure_plugins_styling(opts)
      end

      def configure_scales_styling(opts)
        opts[:scales] ||= {}

        # Symbols, not Strings: deep_merge in build_options only merges the
        # caller's `scales:` into these entries when the keys are the same kind.
        %i[x y].each do |axis|
          configure_axis_styling(opts[:scales], axis)
        end
      end

      def configure_axis_styling(scales, axis)
        scales[axis] ||= {}
        axis_config = scales[axis]

        # Grid: cleaner, more subtle - only show y-axis grid
        axis_config[:grid] = { useThemeColors: true, drawBorder: false, display: (axis == :y) }

        # Ticks with proper font
        axis_config[:ticks] = { useThemeColors: true, font: { family: FONT_FAMILY, size: 12 } }

        # Hide axis border
        axis_config[:border] = { display: false }
      end

      def configure_plugins_styling(opts)
        opts[:plugins] ||= {}

        # Tooltip
        opts[:plugins][:tooltip] ||= {}
        opts[:plugins][:tooltip][:useThemeColors] = true

        # Legend font
        opts[:plugins][:legend] ||= {}
        opts[:plugins][:legend][:labels] ||= {}
        opts[:plugins][:legend][:labels][:font] = { family: FONT_FAMILY, size: 12, weight: "500" }
      end

      def labels
        @labels ||= extract_labels
      end

      def extract_labels
        if @data.key?(:labels) || (@data.keys.size == 1 && @data.key?(:datasets))
          Array.wrap(@data[:labels])
        else
          @data.keys.map(&:to_s)
        end
      end

      def truncated_labels
        @truncated_labels ||= labels.map { |label| label.to_s.truncate(MAX_LABEL_LENGTH) }
      end

      def datasets
        @datasets ||= build_datasets
      end

      def build_datasets
        raw_datasets = @data[:datasets]&.deep_dup || [ { label: "", data: @data.values } ]

        raw_datasets.map.with_index do |dataset_info, index|
          build_dataset(dataset_info, index)
        end
      end

      def build_dataset(info, index)
        info[:type] ||= @types[index] || @types.first
        info[:order] ||= @order[index]
        info[:yAxisID] ||= @y_axis_ids[index]

        # Add rounded corners for bar charts
        dataset_type = info[:type]&.to_sym
        is_bar = BAR_TYPES.include?(dataset_type)

        Dataset.new(
          color: colors_for_type(info[:type], info[:data]),
          rounded: is_bar,
          **info.compact
        ).to_h
      end

      def colors_for_type(graph_type, data = [])
        if MULTI_COLOR_TYPES.include?(graph_type&.to_sym)
          # For pie/doughnut/polarArea, need one color per data point
          # Use labels count if available, otherwise count data points
          color_count = labels.any? ? labels.size : Array.wrap(data).size
          color_count = [ color_count, 1 ].max # Ensure at least 1 color
          color_count.times.map { @color_picker.next_color }
        else
          [ @color_picker.next_color ]
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
