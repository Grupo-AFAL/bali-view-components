# frozen_string_literal: true

module Bali
  module Widget
    module List
      # HOW MANY, AND WHICH — the whole card for a `ListBase` widget.
      #
      # The count is the headline and the rows are the breakdown, which makes
      # this the one type that fills that region with data rather than an empty
      # message. `Bali::Widget::Rows` draws them; this decides how many fit.
      class Component < Value::Component
        private

        # `items`, not `rows`: a widget loads `ListBase::PREVIEW_ROWS` regardless
        # of the size it is rendered at, and the CARD truncates to what its
        # canvas has room for. That split is what lets a widget stay ignorant of
        # its size.
        def detail_content
          return if rows.empty?

          render Bali::Widget::Rows::Component.new(rows)
        end

        def rows = @rows ||= widget.items.first(row_budget)
      end
    end
  end
end
