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
          variant: variant.to_sym,
          size: size.to_sym,
          disabled: disabled,
          loading: loading
        ) { 'Button' }
      end

      def with_icon
        render Bali::Button::Component.new(variant: :primary, icon_name: 'plus') { 'Add Item' }
      end

      def button_group
        render_with_template
      end
    end
  end
end
