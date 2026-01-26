# frozen_string_literal: true

module Bali
  module Button
    class Preview < Lookbook::Preview
      # @param variant select { choices: [primary, secondary, accent, info, success, warning, error, ghost, link, neutral, outline] }
      # @param size select { choices: [xs, sm, md, lg, xl] }
      # @param disabled toggle
      # @param loading toggle
      def default(variant: :primary, size: :md, disabled: false, loading: false)
        render Bali::Button::Component.new(
          name: 'Button',
          variant: variant.to_sym,
          size: size.to_sym,
          disabled: disabled,
          loading: loading
        )
      end

      def with_icon
        render Bali::Button::Component.new(name: 'Add Item', variant: :primary, icon_name: 'plus')
      end

      # @label Button Group
      # Shows buttons grouped together with consistent spacing
      def button_group
        buttons = safe_join([
          render(Bali::Button::Component.new(name: 'Cancel', variant: :ghost)),
          render(Bali::Button::Component.new(name: 'Confirm', variant: :primary))
        ])
        %(<div class="flex gap-2">#{buttons}</div>).html_safe
      end
    end
  end
end
