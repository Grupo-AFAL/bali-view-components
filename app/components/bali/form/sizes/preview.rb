# frozen_string_literal: true

module Bali
  module Form
    module Sizes
      # `size:` across the whole builder, in one place, because the question it
      # answers is a cross-family one: does a form written entirely at one
      # density actually come out at that density? The per-family previews show
      # the option next to the rest of that family's options; these two show it
      # against every other control it will sit beside.
      class Preview < ApplicationViewComponentPreview
        # @label Compact form
        # Every family at `size: :sm` in a sidebar-width column — the case this
        # exists for. The captions, help text and error messages take no variant
        # of their own and need none: `fieldset-legend` and `fieldset-label` are
        # 12px at every density.
        def compact
          render_with_template(
            template: "bali/form/sizes/previews/compact",
            locals: { model: sized_record }
          )
        end

        # @label Default vs compact
        # The same fields side by side, so the difference is the option and
        # nothing else.
        def comparison
          render_with_template(
            template: "bali/form/sizes/previews/comparison",
            locals: { model: sized_record }
          )
        end

        private

        # One field is invalid on purpose: the error paragraph and the `*-error`
        # class are part of what has to still look right at a smaller density.
        def sized_record
          form_record.tap { |record| record.errors.add(:email, :invalid) }
        end
      end
    end
  end
end
