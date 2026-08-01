# frozen_string_literal: true

module Bali
  module Heatmap
    class Preview < ApplicationViewComponentPreview
      # Heatmap
      # -------------------
      # A data visualization that shows magnitude as color intensity across two dimensions.
      # Useful for displaying patterns in time-based data like activity by hour/day.
      #
      # By default, the heatmap is responsive and fills its container width.
      #
      # `color:` names a DaisyUI theme colour and the ramp is built out of that
      # theme *variable*, so changing the theme repaints the heatmap. Before v3
      # these were hardcoded hex and `:primary` meant indigo whatever the theme
      # said. `custom_color:` takes a hex and deliberately does not follow it.
      #
      # @param color select { choices: [neutral, primary, secondary, accent, info, success, warning, error, ghost] }
      # @param responsive toggle
      def default(color: :primary, responsive: true)
        data = {
          Mon: { 9 => 5, 10 => 8, 11 => 3, 12 => 7 },
          Tue: { 9 => 3, 10 => 6, 11 => 9, 12 => 4 },
          Wed: { 9 => 2, 10 => 4, 11 => 6, 12 => 8 },
          Thu: { 9 => 7, 10 => 5, 11 => 3, 12 => 6 },
          Fri: { 9 => 4, 10 => 7, 11 => 8, 12 => 9 }
        }

        render Bali::Heatmap::Component.new(
          data: data,
          color: color.to_sym,
          responsive: responsive
        ) do |c|
          c.with_x_axis_title('Days')
          c.with_y_axis_title('Hours')
          c.with_hovercard_title('Clicks by hour of day')
          c.with_legend_title('Clicks')
        end
      end

      # Shows a heatmap with all zero values - validates edge case handling
      def with_zero_values
        data = {
          A: { 0 => 0, 1 => 0 },
          B: { 0 => 0, 1 => 0 }
        }

        render Bali::Heatmap::Component.new(data: data, color: :info) do |c|
          c.with_legend_title('Value')
        end
      end

      # Minimal configuration without optional slots
      def minimal
        data = {
          Q1: { 2023 => 150, 2024 => 200, 2025 => 180 },
          Q2: { 2023 => 180, 2024 => 220, 2025 => 250 },
          Q3: { 2023 => 120, 2024 => 190, 2025 => 210 },
          Q4: { 2023 => 200, 2024 => 240, 2025 => 280 }
        }

        render Bali::Heatmap::Component.new(data: data, color: :info)
      end

      # Larger dataset demonstrating full-week activity patterns
      def large_dataset
        days = %i[Sun Mon Tue Wed Thu Fri Sat]
        hours = (6..22)

        data = days.index_with do |_day|
          hours.index_with { |_hour| rand(0..100) }
        end

        render Bali::Heatmap::Component.new(
          data: data,
          color: :error
        ) do |c|
          c.with_x_axis_title('Day of Week')
          c.with_y_axis_title('Hour')
          c.with_hovercard_title('Activity Level')
          c.with_legend_title('Activity')
        end
      end

      # Y keys that are labels rather than a numeric scale: one row per key, in the
      # order given. No range is inferred, because there is no range to infer.
      def with_string_y_keys
        data = {
          Mon: { 'morning' => 5, 'afternoon' => 8, 'evening' => 3 },
          Tue: { 'morning' => 3, 'afternoon' => 6, 'evening' => 9 },
          Wed: { 'morning' => 2, 'afternoon' => 4, 'evening' => 6 }
        }

        render Bali::Heatmap::Component.new(data: data, color: :success) do |c|
          c.with_x_axis_title('Day')
          c.with_y_axis_title('Shift')
        end
      end

      # The hex escape hatch. Everything else on this page follows the theme;
      # this one does not, which is the whole reason it has its own keyword.
      # @param custom_color text
      def with_custom_color(custom_color: '#7c3aed')
        data = { A: { 0 => 1, 1 => 2 }, B: { 0 => 3, 1 => 4 } }

        render Bali::Heatmap::Component.new(data: data, custom_color: custom_color)
      end

      # Shows every semantic colour at once. Switch the DaisyUI theme with the
      # toolbar and all nine repaint — that is the check that #691 landed.
      def color_presets
        render_with_template
      end
    end
  end
end
