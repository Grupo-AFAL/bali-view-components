# frozen_string_literal: true

module Bali
  module Columns
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default
      # -------
      # Two equal-width columns using size: :half
      def default
        render Columns::Component.new do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'First Column (half)'
            end
          end

          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Second Column (half)'
            end
          end
        end
      end

      # Auto Width
      # ----------
      # A column that only takes the width of its content
      def auto_width
        render Columns::Component.new do |c|
          c.with_column(size: :auto) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p 'Auto'
            end
          end

          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'This column takes remaining space (full width)'
            end
          end
        end
      end

      # @!endgroup

      # @!group Gap Sizes

      # Gap None
      # --------
      # Columns with no gap between them
      def gap_none
        render Columns::Component.new(gap: :none) do |c|
          c.with_column(size: :third) do
            tag.div(class: 'bg-primary text-primary-content p-4') do
              tag.p 'No gap'
            end
          end

          c.with_column(size: :third) do
            tag.div(class: 'bg-secondary text-secondary-content p-4') do
              tag.p 'Between'
            end
          end

          c.with_column(size: :third) do
            tag.div(class: 'bg-accent text-accent-content p-4') do
              tag.p 'Columns'
            end
          end
        end
      end

      # Gap Large
      # ---------
      # Columns with large gap (gap-6)
      def gap_large
        render Columns::Component.new(gap: :lg) do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Large gap'
            end
          end

          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Between columns'
            end
          end
        end
      end

      # @!endgroup

      # @!group Sizing

      # Offset
      # ------
      # A column with left offset using CSS Grid col-start
      def offset
        render Columns::Component.new do |c|
          c.with_column(size: :half, offset: :quarter) do
            tag.div(class: 'bg-secondary text-secondary-content p-4 rounded-lg') do
              tag.p 'Half width with quarter offset'
            end
          end
        end
      end

      # Thirds
      # ------
      # Columns with one-third and two-thirds widths
      def thirds
        render Columns::Component.new do |c|
          c.with_column(size: :third) do
            tag.div(class: 'bg-accent text-accent-content p-4 rounded-lg') do
              tag.p '1/3 width'
            end
          end

          c.with_column(size: :two_thirds) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p '2/3 width'
            end
          end
        end
      end

      # Quarters
      # --------
      # Columns with quarter widths
      def quarters
        render Columns::Component.new do |c|
          c.with_column(size: :quarter) do
            tag.div(class: 'bg-info text-info-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :three_quarters) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p '3/4 width'
            end
          end
        end
      end

      # @!endgroup

      # @!group Multi-row

      # Multiline
      # ---------
      # Columns that span multiple rows in the grid
      def multiline
        render Columns::Component.new do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p '1st (half)'
            end
          end

          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p '2nd (half)'
            end
          end

          c.with_column(size: :third) do
            tag.div(class: 'bg-base-300 p-4 rounded-lg') do
              tag.p '3rd (third)'
            end
          end

          c.with_column(size: :two_thirds) do
            tag.div(class: 'bg-base-300 p-4 rounded-lg') do
              tag.p '4th (two-thirds)'
            end
          end
        end
      end

      # Equal Thirds
      # ------------
      # Three columns of equal width using size: :third
      def equal_thirds
        render Columns::Component.new do |c|
          c.with_column(size: :third) do
            tag.div(class: 'bg-success text-success-content p-4 rounded-lg') do
              tag.p 'Column 1 (1/3)'
            end
          end

          c.with_column(size: :third) do
            tag.div(class: 'bg-warning text-warning-content p-4 rounded-lg') do
              tag.p 'Column 2 (1/3)'
            end
          end

          c.with_column(size: :third) do
            tag.div(class: 'bg-error text-error-content p-4 rounded-lg') do
              tag.p 'Column 3 (1/3)'
            end
          end
        end
      end

      # Equal Quarters
      # --------------
      # Four columns of equal width using size: :quarter
      def equal_quarters
        render Columns::Component.new do |c|
          c.with_column(size: :quarter) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :quarter) do
            tag.div(class: 'bg-secondary text-secondary-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :quarter) do
            tag.div(class: 'bg-accent text-accent-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :quarter) do
            tag.div(class: 'bg-neutral text-neutral-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end
        end
      end

      # @!endgroup
    end
  end
end
