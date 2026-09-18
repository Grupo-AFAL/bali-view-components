# frozen_string_literal: true

module Bali
  module StatCard
    class Preview < ApplicationViewComponentPreview
      # @param title text
      # @param value text
      # @param icon text
      # @param color select { choices: [neutral, primary, secondary, accent, info, success, warning, error, ghost] }
      def default(title: 'Total Users', value: '1,234', icon: 'users', color: :primary)
        render Bali::StatCard::Component.new(
          title: title,
          value: value,
          icon: icon,
          color: color.to_sym
        )
      end

      # The hex escape hatch. `custom_color:` replaces the semantic pair with an
      # inline colour, so it stops following the theme — that is the trade.
      # @param custom_color text
      def with_custom_color(custom_color: '#7c3aed')
        render Bali::StatCard::Component.new(
          title: 'Brand Signups',
          value: '312',
          icon: 'user-plus',
          custom_color: custom_color
        )
      end

      # `href:` renders the whole card as an `<a>` (KPI drill-down to its
      # listing) with a hover shadow affordance. The footer must not contain
      # links then — an `<a>` inside an `<a>` is invalid HTML.
      def clickable
        render Bali::StatCard::Component.new(
          title: 'Open Orders',
          value: '87',
          icon: 'shopping-cart',
          color: :info,
          href: '/lookbook'
        )
      end

      # With footer showing a trend
      def with_trend
        render_with_template(template: 'bali/stat_card/previews/with_trend')
      end

      # With footer showing status
      def with_status
        render_with_template(template: 'bali/stat_card/previews/with_status')
      end

      # `surface: :cell` renders the same figure on a flat bordered box that never
      # emits `.card` — the grid of metrics that lives INSIDE a section card, where
      # the default surface would be a card in a card. No icon badge: six of them in
      # one grid is noise, so `icon:` raises here instead of being dropped in silence.
      def cells_in_card
        render_with_template(template: 'bali/stat_card/previews/cells_in_card')
      end

      # When each box is the right one. `size: :sm, shadow: false` is already a quiet
      # bordered card with 1rem of padding — same padding as the cell — and it is
      # enough whenever nothing else on screen is a card.
      def surfaces_compared
        render_with_template(template: 'bali/stat_card/previews/surfaces_compared')
      end

      # `emphasis: true` paints the cell with the soft pair of `color:`, to single out
      # one figure in a grid. It is an emphasis axis, not a colour axis: which colour
      # is still `color:` (or `custom_color:`, painted inline). `href:` turns the cell
      # into an `<a>` with the same hover-shadow affordance the card surface has.
      #
      # `value_class` is a parameter here so the measurement the guide quotes stays
      # reproducible from the gallery: it is appended verbatim, so `text-xl` really
      # does bring the figure down to 20px. `text-2xl` is the one size that loses.
      # @param color select { choices: [neutral, primary, secondary, accent, info, success, warning, error, ghost] }
      # @param href text
      # @param value_class text
      def emphasised_cell(color: :primary, href: '', value_class: 'tabular-nums')
        render Bali::StatCard::Component.new(
          surface: :cell,
          emphasis: true,
          color: color.to_sym,
          href: href.presence,
          title: 'VPN',
          value: '$6.14M',
          value_class: value_class.presence,
          note: 'Crea valor · tasa 12.5%'
        )
      end
    end
  end
end
