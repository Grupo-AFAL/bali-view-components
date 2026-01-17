# frozen_string_literal: true

module Bali
  module Heatmap
    class Preview < ApplicationViewComponentPreview
      # Heatmap
      # -------------------
      # A data visualization that shows magnitude as color intensity across two dimensions.
      # Useful for displaying patterns in time-based data like activity by hour/day.
      #
      # @param width number
      # @param height number
      # @param color text
      def default(width: 480, height: 480, color: '#008806')
        data = {
          Mon: { 0 => 5, 1 => 10, 2 => 3 },
          Tue: { 0 => 3, 1 => 1, 2 => 6 },
          Wed: { 0 => 2, 1 => 8, 2 => 4 },
          Thu: { 0 => 7, 1 => 2, 2 => 5 },
          Fri: { 0 => 4, 1 => 6, 2 => 9 }
        }

        render Bali::Heatmap::Component.new(
          data: data,
          width: width.to_i,
          height: height.to_i,
          color: color
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

        render Bali::Heatmap::Component.new(data: data) do |c|
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

        render Bali::Heatmap::Component.new(data: data, color: '#3B82F6')
      end

      # Larger dataset demonstrating scalability
      def large_dataset
        days = %i[Sun Mon Tue Wed Thu Fri Sat]
        hours = (0..23)

        data = days.index_with do |_day|
          hours.index_with { |_hour| rand(0..100) }
        end

        render Bali::Heatmap::Component.new(
          data: data,
          width: 800,
          height: 400,
          color: '#DC2626'
        ) do |c|
          c.with_x_axis_title('Day of Week')
          c.with_y_axis_title('Hour')
          c.with_hovercard_title('Activity Level')
          c.with_legend_title('Activity')
        end
      end
    end
  end
end
