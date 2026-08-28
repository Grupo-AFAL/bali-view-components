# frozen_string_literal: true

module Bali
  module Widget
    module Rows
      # THE BREAKDOWN: a list widget's preview rows, already truncated to what
      # the canvas has room for.
      #
      #   render Bali::Widget::Rows::Component.new(rows)
      #
      # `Rows`, not `List` — `Bali::List::Component` is a different component in
      # this library and the card explicitly does NOT use it (see below), so a
      # `Bali::Widget::List` would invite exactly the confusion this name avoids.
      # It also says what it renders: `Bali::Widget::ListBase::Row` objects, which
      # are plain values, so this never touches a model.
      #
      # NOT `Bali::List`, considered and ruled out: its `Item` puts title and
      # subtitle in a bare `<div>` with no way to set a class, and a widget row
      # needs `min-w-0` on that wrapper — which is precisely what makes
      # `truncate` work inside a flex row. Its defaults differ too
      # (`font-semibold`/`text-sm` against this card's `font-medium`/`text-xs`),
      # so composing it means five overrides to defeat five defaults and still
      # leaves the truncation broken. A row that fails to truncate looks fine
      # until a long title arrives, which is why this note exists.
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
