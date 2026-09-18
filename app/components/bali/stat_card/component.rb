# frozen_string_literal: true

module Bali
  module StatCard
    # One metric: a label, the figure, and optionally a discreet note under it.
    #
    # Two surfaces, one design. `surface: :card` (the default) is the dashboard
    # KPI tile — a `Bali::Card`, bordered, with a shadow and the colour badge.
    # `surface: :cell` is the same content on a flat bordered box that never
    # emits `.card`, for a grid of figures that already lives INSIDE a card and
    # must not become a card in a card.
    #
    # This stays one component on purpose. v3 collapsed three stat designs into
    # this one (`Bali::InfoLevel` is deprecated for having been the third); a
    # second component would reopen exactly that divergence. What changes between
    # the two surfaces is the box, not the figure.
    class Component < ApplicationViewComponent
      include Bali::DeprecatedIconName

      # Keyed by Bali::Color::NAMES. Spelled out because Tailwind only emits a
      # class it can find literally in a source file.
      #
      # `:border` is read only by `emphasis: true` on the cell surface. The table
      # has a second consumer — `Bali::DashboardPage#stat_change_class` reads
      # `[:text]` out of it, and this component's own test walks every value — so
      # the key is additive on purpose: nothing reading `:bg`/`:text` sees a change.
      COLORS = {
        neutral: { bg: "bg-neutral/10", text: "text-neutral", border: "border-neutral/30" },
        primary: { bg: "bg-primary/10", text: "text-primary", border: "border-primary/30" },
        secondary: { bg: "bg-secondary/10", text: "text-secondary",
                     border: "border-secondary/30" },
        accent: { bg: "bg-accent/10", text: "text-accent", border: "border-accent/30" },
        info: { bg: "bg-info/10", text: "text-info", border: "border-info/30" },
        success: { bg: "bg-success/10", text: "text-success", border: "border-success/30" },
        warning: { bg: "bg-warning/10", text: "text-warning", border: "border-warning/30" },
        error: { bg: "bg-error/10", text: "text-error", border: "border-error/30" },
        ghost: { bg: "bg-base-200", text: "text-base-content", border: "border-base-300" }
      }.freeze

      DEFAULT_COLOR = :primary

      DEFAULT_SURFACE = :card

      SURFACES = %i[card cell].freeze

      # `Bali::Card#initialize`'s keywords. A cell renders no card, so these had
      # nowhere to go and landed on the root as HTML attributes
      # (`<div size="sm" shadow="false">`, measured); `reject_card_keywords_on_a_cell!`
      # says so out loud instead, the way `icon:` already does. `href:` is not
      # in the list — the cell honours it — and `style:` is handled on its own,
      # because it is also a real HTML attribute.
      CARD_KEYWORDS = %i[size side image_full shadow body_class].freeze

      # The cell's box. `rounded-box border border-base-300` is the spelling the
      # library already uses for a bordered container
      # (`Bali::List::Component::BORDERED_CLASSES`), and `p-4` is 1rem — the same
      # inner padding daisyUI gives `.card-sm`'s body, so a call site moving
      # between `surface: :card, size: :sm` and `surface: :cell` keeps its
      # measurements. The host workaround's `p-3.5` is a step Bali uses nowhere.
      CELL_CLASSES = "rounded-box border p-4"
      CELL_SURFACE_CLASSES = "bg-base-100 border-base-300"

      # The figure's type scale. It lives here, in one place, because that is where a
      # decision about how big every figure in the library is belongs — `value_class:`
      # appends after it and can outrank it, but one call site at a time is not how the
      # scale changes.
      VALUE_CLASSES = "text-3xl font-bold mt-1"
      NOTE_CLASSES = "text-base-content/60 mt-1 text-xs"

      # Everything the cell needed for itself. The template reaches private
      # constants and private methods without complaining, and `COLORS` already
      # carries this component's one outside consumer
      # (`Bali::DashboardPage#stat_change_class`) — a dozen more public symbols
      # would be surface nobody asked for and a deprecation cycle to take back.
      private_constant :SURFACES, :CARD_KEYWORDS, :CELL_CLASSES, :CELL_SURFACE_CLASSES,
                       :VALUE_CLASSES, :NOTE_CLASSES

      renders_one :footer

      # @param title [String] Label above the value
      # @param value [String, Numeric] The figure the card exists to show
      # @param note [String, nil] A discreet muted line under the value ("Crea valor ·
      #   tasa 12.5%"). Not the `footer` slot, which is the trend/status row at the bottom.
      # @param icon [String] Lucide icon name. Card surface only.
      # @param color [Symbol] Semantic colour of the icon badge — and of the cell tint when
      #   `emphasis:` is on (Bali::Color::NAMES)
      # @param custom_color [String, nil] Hex colour for the icon badge / the cell tint
      # @param surface [Symbol] `:card` (default, and what `nil` falls back to) renders a
      #   `Bali::Card`; `:cell` renders a flat bordered box that never emits `.card`, for
      #   grids inside a card.
      # @param emphasis [Boolean] Cell surface only: paints the cell with the soft pair of
      #   `color:` (or of `custom_color:`) to single out one figure. An emphasis axis, not a
      #   colour axis — which colour it is stays `color:`/`custom_color:`.
      # @param value_class [String, nil] Classes appended after the value's own. Meant for
      #   properties the library does not set (`font-mono`, `tabular-nums`, a colour). It
      #   filters nothing: a size utility here does win — measured, `text-xl` renders at 20px
      #   — because the compiled sheet's order decides, not this string. `text-2xl` is the one
      #   size that loses to `text-3xl`. To change the scale, change VALUE_CLASSES.
      # @param href [String, nil] Renders the whole card/cell as an `<a>` (KPI drill-down).
      #   The `footer` slot must not contain links then — an `<a>` inside an `<a>` is
      #   invalid HTML.
      # @param icon_name [String, nil] @deprecated Removed in Bali 4.0. Use `icon:`.
      # rubocop:disable Metrics/ParameterLists
      def initialize(title:, value:, icon: nil, color: DEFAULT_COLOR, custom_color: nil,
                     href: nil, note: nil, surface: DEFAULT_SURFACE, emphasis: false,
                     value_class: nil, icon_name: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        @title = title
        @value = value
        @note = note
        @icon = icon || deprecated_icon_name(icon_name)
        @custom_color = Bali::Color.hex!(self.class, custom_color)
        @color = @custom_color ? nil : Bali::Color.name!(self.class, color || DEFAULT_COLOR)
        @surface = surface!(surface)
        @emphasis = emphasis
        @value_class = value_class
        @href = href
        @options = options

        reject_icon_on_a_cell!
        reject_card_keywords_on_a_cell!
        reject_emphasis_on_a_card!
      end

      def card_options
        @options.merge(style: :bordered, href: @href)
      end

      def icon_container_classes
        class_names("p-3 rounded-full", icon_bg_class)
      end

      def icon_container_style
        return if @custom_color.blank?

        "background-color: #{Bali::Color.with_alpha(@custom_color, 10)}"
      end

      def icon_bg_class
        COLORS.dig(@color, :bg)
      end

      def icon_text_class
        COLORS.dig(@color, :text)
      end

      def icon_style
        "color: #{@custom_color}" if @custom_color.present?
      end

      private

      attr_reader :title, :value, :note, :icon, :color, :options

      def cell?
        @surface == :cell
      end

      # The cell keeps the passthrough the card surface has always had: `class:`,
      # `id:` and `data:` reach the root element, with the cell's own classes
      # prepended rather than replacing what the host sent.
      def cell_options
        options = prepend_class_name(@options.dup, cell_classes)
        options = prepend_style(options, cell_style) if cell_style
        options[:href] = @href if @href.present?
        options
      end

      def cell_tag
        @href.present? ? :a : :div
      end

      def cell_classes
        class_names(
          CELL_CLASSES,
          cell_surface_classes,
          "transition-shadow hover:shadow-md" => @href.present?
        )
      end

      # A hex `custom_color:` has no class pair to reach for, so its tint goes
      # inline — the same escape hatch, and the same `color-mix`, the icon badge
      # already uses. Without this an emphasised cell with `custom_color:` would
      # paint nothing at all, in silence.
      #
      # No trailing `;`: `prepend_style` is what joins this to a host's own
      # `style:`, and it puts the separator in (lib/bali/html_element_helper.rb).
      def cell_style
        return unless @emphasis && @custom_color.present?

        "background-color: #{Bali::Color.with_alpha(@custom_color, 10)}; " \
          "border-color: #{Bali::Color.with_alpha(@custom_color, 30)}"
      end

      def value_classes
        class_names(VALUE_CLASSES, @value_class)
      end

      def note_classes
        NOTE_CLASSES
      end

      # Either the plain surface or the tinted pair, never both: `border-base-300`
      # and `border-primary/30` set the same property in the same layer, so which
      # one wins would come down to Tailwind's output order.
      #
      # `bg-base-100` is a no-op in the case the cell exists for — measured, the
      # section card paints the same `oklch(1 0 0)` behind it — and it is there
      # for every other case: dropped on a page's own `base-200` ground, a
      # transparent cell is a grey box with a line around it.
      def cell_surface_classes
        return CELL_SURFACE_CLASSES unless @emphasis && @color

        "#{COLORS.dig(@color, :bg)} #{COLORS.dig(@color, :border)}"
      end

      # `nil` falls back the way `color:` does one line above it in the same
      # `initialize`, and the way `Bali::Card` takes `style: nil`: a host writing
      # `surface: condition ? :cell : nil` gets the default, not an exception.
      def surface!(value)
        key = value.nil? ? DEFAULT_SURFACE : value
        key = key.to_sym if key.respond_to?(:to_sym)
        return key if SURFACES.include?(key)

        raise ArgumentError,
              "#{self.class}: unknown surface #{value.inspect}. " \
              "Valid: #{SURFACES.map(&:inspect).join(', ')}."
      end

      # Six icon badges in a grid inside a card is noise, so the cell has nowhere
      # to put one. Dropping it in silence would leave a host wondering where
      # their icon went, which is the whole reason this raises instead.
      def reject_icon_on_a_cell!
        return unless cell? && @icon.present?

        raise ArgumentError,
              "#{self.class}: surface: :cell renders no icon badge, so icon: " \
              "#{@icon.inspect} would be dropped. Remove it, or use surface: :card."
      end

      # The same rule as `icon:`, kept even. These are `Bali::Card`'s keywords;
      # a cell renders no card, so they used to fall through `**options` and
      # land on the root as invalid HTML attributes (`<div size="sm"
      # shadow="false" body_class="x">`, measured in the browser). Rejecting one
      # keyword and dropping five in silence was the asymmetry, not the rule.
      #
      # `style:` is the one that is BOTH — Card's (a Symbol: `:bordered`) and a
      # real HTML attribute (a String). Only the Symbol is rejected; a String
      # inline style is legitimate on the root and rides along with the
      # `emphasis:` tint.
      def reject_card_keywords_on_a_cell!
        return unless cell?

        offenders = CARD_KEYWORDS & @options.keys
        offenders << :style if @options[:style].is_a?(Symbol)
        return if offenders.empty?

        named = offenders.map { |key| "#{key}: #{@options[key].inspect}" }.join(", ")
        raise ArgumentError,
              "#{self.class}: surface: :cell renders no Bali::Card, so #{named} " \
              "would land on the root as an HTML attribute. Remove them, or use " \
              "surface: :card."
      end

      def reject_emphasis_on_a_card!
        return unless @emphasis && !cell?

        raise ArgumentError,
              "#{self.class}: emphasis: is a surface: :cell option. The card surface " \
              "brings its own bg-base-100, and tinting over it would come down to " \
              "Tailwind's output order."
      end
    end
  end
end
