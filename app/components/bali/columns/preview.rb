# frozen_string_literal: true

module Bali
  module Columns
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default
      # -------
      # Columns without size specifications fill available space equally.
      # Stacks on mobile, side-by-side on md+ (768px).
      def default
        render Columns::Component.new do |c|
          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "First Column"
            end
          end

          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "Second Column"
            end
          end

          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "Third Column"
            end
          end
        end
      end

      # Auto Width
      # ----------
      # A column that only takes the width of its content.
      def auto_width
        render Columns::Component.new do |c|
          c.with_column(auto: true) do
            tag.div(class: "bg-primary text-primary-content p-4 rounded-lg") do
              tag.p "Auto"
            end
          end

          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "This column fills remaining space"
            end
          end
        end
      end

      # @!endgroup

      # @!group Gap & Alignment

      # Gap Sizes
      # ---------
      # Control spacing between columns. Default is `:md` (gap-3).
      # @param gap select { choices: [none, px, xs, sm, md, lg, xl, 2xl] }
      def gap_sizes(gap: :md)
        render Columns::Component.new(gap: gap.to_sym) do |c|
          c.with_column(size: :one_third) do
            tag.div(class: "bg-primary text-primary-content p-4 rounded-lg") do
              tag.p "gap: :#{gap}"
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: "bg-secondary text-secondary-content p-4 rounded-lg") do
              tag.p "Between"
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: "bg-accent text-accent-content p-4 rounded-lg") do
              tag.p "Columns"
            end
          end
        end
      end

      # Alignment
      # ---------
      # `center:` aligns horizontally, `middle:` aligns vertically.
      # @param center toggle
      # @param middle toggle
      def alignment(center: false, middle: false)
        render Columns::Component.new(center: center, middle: middle) do |c|
          c.with_column(size: :half) do
            tag.div(class: "bg-base-200 p-4 rounded-lg", style: "height: 120px;") do
              tag.p "Tall column"
            end
          end

          c.with_column(size: :one_quarter) do
            tag.div(class: "bg-secondary text-secondary-content p-4 rounded-lg") do
              tag.p "Short column"
            end
          end
        end
      end

      # Mobile
      # ------
      # By default columns stack on mobile. Set `mobile: true` to keep them horizontal.
      # @param mobile toggle
      def mobile(mobile: false)
        render Columns::Component.new(mobile: mobile) do |c|
          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "Column 1"
            end
          end

          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "Column 2"
            end
          end

          c.with_column do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "Column 3"
            end
          end
        end
      end

      # @!endgroup

      # @!group Sizing

      # Numeric Sizes
      # -------------
      # Use numeric sizes 1-12 for precise control.
      def numeric_sizes
        render Columns::Component.new do |c|
          c.with_column(size: 4) do
            tag.div(class: "bg-primary text-primary-content p-4 rounded-lg") do
              tag.p "size: 4 (w-4/12)"
            end
          end

          c.with_column(size: 8) do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "size: 8 (w-8/12)"
            end
          end
        end
      end

      # Fractional Sizes
      # ----------------
      # Symbolic sizes for common splits.
      # @param split select { choices: [halves, thirds, quarters, fifths] }
      def fractional_sizes(split: :halves)
        configs = {
          "halves"   => [ [ :half, "bg-base-200" ], [ :half, "bg-base-300" ] ],
          "thirds"   => [ [ :one_third, "bg-accent text-accent-content" ], [ :two_thirds, "bg-base-200" ] ],
          "quarters" => [ [ :one_quarter, "bg-info text-info-content" ], [ :three_quarters, "bg-base-200" ] ],
          "fifths"   => [ [ :one_fifth, "bg-primary text-primary-content" ], [ :four_fifths, "bg-base-200" ] ]
        }

        cols = configs[split.to_s] || configs["halves"]

        render Columns::Component.new do |c|
          cols.each do |size, color|
            c.with_column(size: size) do
              tag.div(class: "#{color} p-4 rounded-lg") do
                tag.p "#{size} width"
              end
            end
          end
        end
      end

      # Equal Columns
      # -------------
      # Equal-width columns using fractional sizes.
      # @param count select { choices: [3, 4, 12] }
      def equal_columns(count: 3)
        n = count.to_i
        colors = %w[bg-success bg-warning bg-error bg-primary bg-secondary bg-accent
                     bg-info bg-base-300 bg-success bg-warning bg-error bg-primary]
        size = { 3 => :one_third, 4 => :one_quarter, 12 => 1 }[n] || :one_third

        render Columns::Component.new(mobile: n == 12) do |c|
          n.times do |i|
            c.with_column(size: size) do
              text_class = colors[i].include?("base") ? "" : "text-#{colors[i].delete_prefix('bg-')}-content"
              tag.div(class: "#{colors[i]} #{text_class} p-#{n == 12 ? 2 : 4} rounded-lg text-center") do
                tag.p((i + 1).to_s)
              end
            end
          end
        end
      end

      # Wrap
      # ----
      # Columns that wrap to multiple lines when they exceed container width.
      def wrap
        render Columns::Component.new(wrap: true) do |c|
          c.with_column(size: :half) do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "1st (half)"
            end
          end

          c.with_column(size: :half) do
            tag.div(class: "bg-base-200 p-4 rounded-lg") do
              tag.p "2nd (half)"
            end
          end

          c.with_column(size: :one_third) do
            tag.div(class: "bg-base-300 p-4 rounded-lg") do
              tag.p "3rd (third)"
            end
          end

          c.with_column(size: :two_thirds) do
            tag.div(class: "bg-base-300 p-4 rounded-lg") do
              tag.p "4th (two-thirds)"
            end
          end
        end
      end

      # @!endgroup

      # @!group Responsive

      # Responsive Stat Cards
      # ---------------------
      # 4 stat cards: stacked on mobile, 2-up on md (768px+), 4-up on lg (1024px+).
      # Uses `md: :half` and `lg: :one_quarter` on each column.
      def responsive_stat_cards
        render_with_template
      end

      # Responsive Main + Sidebar
      # -------------------------
      # Stacked on mobile, 2/3 + 1/3 split on lg (1024px+).
      # Uses `lg: :two_thirds` and `lg: :one_third`.
      def responsive_main_sidebar
        render_with_template
      end

      # Responsive Three Breakpoints
      # -----------------------------
      # 6 items: 2-up on mobile, 3-up on md, 4-up on lg.
      # Uses `size: :half`, `md: :one_third`, `lg: :one_quarter`.
      def responsive_three_breakpoints
        render_with_template
      end

      # @!endgroup

      # @!group Grid Mode

      # Grid Auto-Flow
      # ---------------
      # Use `cols:` to enable CSS Grid auto-flow mode. Children render directly
      # without needing `with_column` wrappers — ideal for forms and card grids.
      # Resize the browser to see responsive breakpoints.
      def grid_auto_flow
        render_with_template
      end

      # Grid Form Layout
      # -----------------
      # Common pattern: form fields in a 2-column grid on md+.
      # Uses `cols: 1, cols_md: 2` for stacked → side-by-side.
      def grid_form_layout
        render_with_template
      end

      # @!endgroup
    end
  end
end
