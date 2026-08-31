# frozen_string_literal: true

module Bali
  module Widget
    module Rows
      # THE BREAKDOWN: a list widget's preview rows, already truncated to what
      # the canvas has room for.
      #
      #   render Bali::Widget::Rows::Component.new(rows)
      #
      # NOT `Bali::List::Component`, which cannot set a class on the wrapper its
      # `Item` puts title and subtitle in — and a widget row needs `min-w-0`
      # there, which is what makes `truncate` work inside a flex row.
      class Component < ApplicationViewComponent
        def initialize(rows, **options)
          @rows = rows
          @options = options
          super()
        end

        def any? = rows.any?

        private

        attr_reader :rows, :options

        # Hiding the `ul` directly cannot work — daisyUI's `.list` sets `display`
        # from `@layer utilities`, which beats anything Bali puts in
        # `@layer components` regardless of specificity. So the caller decides
        # whether to render this at all.
        def classes
          class_names("list min-h-0 flex-1 overflow-hidden", options[:class])
        end
      end
    end
  end
end
