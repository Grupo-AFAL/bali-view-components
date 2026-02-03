# frozen_string_literal: true

module Bali
  module Columns
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default
      # -------
      # Columns without size specifications will automatically fill available space equally.
      def default
        render Columns::Component.new do |c|
          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'First Column'
            end
          end

          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Second Column'
            end
          end

          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Third Column'
            end
          end
        end
      end

      # Auto Width
      # ----------
      # A column that only takes the width of its content (col-auto)
      def auto_width
        render Columns::Component.new do |c|
          c.with_column(auto: true) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p 'Auto'
            end
          end

          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'This column fills remaining space'
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
          c.with_column(size: :one_third) do
            tag.div(class: 'bg-primary text-primary-content p-4') do
              tag.p 'No gap'
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: 'bg-secondary text-secondary-content p-4') do
              tag.p 'Between'
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: 'bg-accent text-accent-content p-4') do
              tag.p 'Columns'
            end
          end
        end
      end

      # Gap Extra Large
      # ---------------
      # Columns with extra large gap (gap: :xl = 1.5rem)
      def gap_xl
        render Columns::Component.new(gap: :xl) do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Large gap (xl)'
            end
          end

          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Between columns'
            end
          end
        end
      end

      # Gap Small
      # ---------
      # Columns with small gap (gap: :sm = 0.5rem)
      def gap_sm
        render Columns::Component.new(gap: :sm) do |c|
          c.with_column(size: :one_third) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Small gap'
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Between'
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Columns'
            end
          end
        end
      end

      # @!endgroup

      # @!group Sizing

      # Numeric Sizes
      # -------------
      # Use numeric sizes 1-12 (col-4, col-8, etc.)
      def numeric_sizes
        render Columns::Component.new do |c|
          c.with_column(size: 4) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p 'size: 4 (col-4)'
            end
          end

          c.with_column(size: 8) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'size: 8 (col-8)'
            end
          end
        end
      end

      # Offset
      # ------
      # A column with left offset (offset-*)
      def offset
        render Columns::Component.new do |c|
          c.with_column(size: :half, offset: :one_quarter) do
            tag.div(class: 'bg-secondary text-secondary-content p-4 rounded-lg') do
              tag.p 'Half width with quarter offset'
            end
          end
        end
      end

      # Numeric Offset
      # --------------
      # Using numeric offset (offset-3)
      def numeric_offset
        render Columns::Component.new do |c|
          c.with_column(size: 6, offset: 3) do
            tag.div(class: 'bg-accent text-accent-content p-4 rounded-lg') do
              tag.p 'size: 6, offset: 3'
            end
          end
        end
      end

      # Halves
      # ------
      # Two columns of equal width using size: :half
      def halves
        render Columns::Component.new do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'First half'
            end
          end

          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Second half'
            end
          end
        end
      end

      # Thirds
      # ------
      # Columns with one-third and two-thirds widths
      def thirds
        render Columns::Component.new do |c|
          c.with_column(size: :one_third) do
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
          c.with_column(size: :one_quarter) do
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

      # Fifths
      # ------
      # Columns with fifth-based widths (col-fifth, col-4-fifths, etc.)
      def fifths
        render Columns::Component.new do |c|
          c.with_column(size: :one_fifth) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p '1/5'
            end
          end

          c.with_column(size: :four_fifths) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p '4/5 width'
            end
          end
        end
      end

      # @!endgroup

      # @!group Alignment

      # Center
      # ------
      # Horizontally centered columns (columns-center)
      def center
        render Columns::Component.new(center: true) do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p 'Centered half-width column'
            end
          end
        end
      end

      # Middle
      # ------
      # Vertically centered columns (columns-middle)
      def middle
        render Columns::Component.new(middle: true) do |c|
          c.with_column(size: :half) do
            tag.div(class: 'bg-base-200 p-4 rounded-lg', style: 'height: 150px;') do
              tag.p 'Tall column'
            end
          end

          c.with_column(size: :half) do
            tag.div(class: 'bg-secondary text-secondary-content p-4 rounded-lg') do
              tag.p 'Vertically centered'
            end
          end
        end
      end

      # Mobile
      # ------
      # Columns that stay horizontal on mobile (columns-mobile)
      def mobile
        render Columns::Component.new(mobile: true) do |c|
          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Column 1'
            end
          end

          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Column 2'
            end
          end

          c.with_column do
            tag.div(class: 'bg-base-200 p-4 rounded-lg') do
              tag.p 'Column 3'
            end
          end
        end
      end

      # @!endgroup

      # @!group Multi-row

      # Wrap
      # ----
      # Columns that wrap to multiple lines (columns-wrap)
      def wrap
        render Columns::Component.new(wrap: true) do |c|
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

          c.with_column(size: :one_third) do
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
      # Three columns of equal width using size: :one_third
      def equal_thirds
        render Columns::Component.new do |c|
          c.with_column(size: :one_third) do
            tag.div(class: 'bg-success text-success-content p-4 rounded-lg') do
              tag.p 'Column 1 (1/3)'
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: 'bg-warning text-warning-content p-4 rounded-lg') do
              tag.p 'Column 2 (1/3)'
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: 'bg-error text-error-content p-4 rounded-lg') do
              tag.p 'Column 3 (1/3)'
            end
          end
        end
      end

      # Equal Quarters
      # --------------
      # Four columns of equal width using size: :one_quarter
      def equal_quarters
        render Columns::Component.new do |c|
          c.with_column(size: :one_quarter) do
            tag.div(class: 'bg-primary text-primary-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :one_quarter) do
            tag.div(class: 'bg-secondary text-secondary-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :one_quarter) do
            tag.div(class: 'bg-accent text-accent-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end

          c.with_column(size: :one_quarter) do
            tag.div(class: 'bg-neutral text-neutral-content p-4 rounded-lg') do
              tag.p '1/4'
            end
          end
        end
      end

      # 12 Column Grid
      # --------------
      # Demonstrating the full 12-column grid with numeric sizes
      def twelve_column_grid
        render Columns::Component.new(mobile: true) do |c|
          12.times do |i|
            c.with_column(size: 1) do
              tag.div(class: 'bg-base-300 p-2 rounded text-center text-xs') do
                tag.p((i + 1).to_s)
              end
            end
          end
        end
      end

      # @!endgroup
    end
  end
end
