# frozen_string_literal: true

module Bali
  module Alert
    # The one daisyUI alert in the library.
    #
    # v2 shipped three wrappers around the same `.alert`: `Bali::Message` (inline),
    # `Bali::Notification` (floating, auto-dismissing) and `Bali::FlashNotifications`
    # (a pair of Notifications). They disagreed on the keyword that picks a colour
    # (`color:` vs `type:`), on which colour names existed, on the ARIA role, and on
    # what "dismiss" meant -- `Message(dismissible:)` was a close button while
    # `Notification(dismiss:)` was the auto-dismiss timer. This is the merge of the
    # three. `Bali::Toast` is now a preset of this component, and
    # `Bali::ToastContainer` only positions a stack of them.
    class Component < ApplicationViewComponent
      BASE_CLASSES = "alert alert-component"

      # daisyUI 5 ships exactly four alert colours. `:neutral` is the absence of a
      # colour class -- daisyUI's own default alert -- and is spelled out so the
      # keyword takes a name in every case instead of `nil` meaning something.
      #
      # There is no `alert-primary`, `alert-secondary` or `alert-accent`, which is
      # why this is a subset of Bali::Color::NAMES rather than the whole palette:
      # v2's `primary`, `secondary` and `link` all silently rendered `alert-info`.
      COLORS = {
        neutral: "",
        info: "alert-info",
        success: "alert-success",
        warning: "alert-warning",
        error: "alert-error"
      }.freeze

      SIZES = {
        small: "text-sm",
        regular: "",
        medium: "text-base",
        large: "text-lg"
      }.freeze

      STYLES = {
        soft: "alert-soft",
        outline: "alert-outline",
        dash: "alert-dash"
      }.freeze

      # What `icon: true` resolves to. A string or symbol names an icon directly.
      ICONS = {
        neutral: "info",
        info: "info",
        success: "circle-check",
        warning: "triangle-alert",
        error: "circle-x"
      }.freeze

      # Allowed ARIA live-region roles. `alert` is assertive -- it interrupts the
      # screen reader mid-sentence -- `status` is polite, `note` is not a live
      # region at all.
      ROLES = %i[alert status note].freeze

      # Only an error earns the interruption. v2's Message defaulted every message
      # to `alert`, so an informational banner interrupted whatever the screen
      # reader was reading.
      ASSERTIVE_COLORS = %i[error].freeze

      renders_one :header

      # Role precedence, highest first:
      #   1. `role:` -- validated against ROLES, an unknown value raises.
      #   2. `assertive: true` -- sugar for role :alert.
      #   3. `polite: true` -- sugar for role :status.
      #   4. derived from `color:` -- :alert for :error, :status for everything else.
      # `assertive:` wins over `polite:` when both are given.
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(title: nil, color: :info, size: :regular, style: nil, icon: nil,
                     role: nil, polite: false, assertive: false,
                     closable: false, dismiss_id: nil, duration: nil, **options)
        @title = title
        @color = Color.name!(self.class.name, color, allowed: COLORS.keys) || :neutral
        @size = size&.to_sym
        @style = style&.to_sym
        @icon = icon
        @role = resolve_role(role, polite: polite, assertive: assertive)
        @closable = closable
        @dismiss_id = dismiss_id
        @duration = duration
        @options = prepend_class_name(options, alert_classes)
        @options = build_controller_options(@options) if controller?
      end
      # rubocop:enable Metrics/ParameterLists

      private

      attr_reader :title, :role, :options

      def closable? = @closable

      def icon? = @icon.present?

      def icon_name
        return ICONS.fetch(@color, ICONS[:info]) if @icon == true

        @icon.to_s
      end

      # The Stimulus controller earns its place when there is something for it to
      # do: a close button to wire, a dismissal to remember, or a timer to run.
      def controller?
        closable? || @dismiss_id.present? || @duration.present?
      end

      def resolve_role(role, polite:, assertive:)
        return validated_role(role) if role
        return :alert if assertive
        return :status if polite

        ASSERTIVE_COLORS.include?(@color) ? :alert : :status
      end

      def validated_role(role)
        key = role.to_sym
        return key if ROLES.include?(key)

        raise ArgumentError,
              "#{self.class.name}: unknown role #{key.inspect}. " \
              "Valid: #{ROLES.map(&:inspect).join(', ')}."
      end

      def build_controller_options(options)
        options = prepend_controller(options, "alert")
        prepend_values(options, "alert", dismiss_id: @dismiss_id, duration: @duration)
      end

      # Ghost/circle icon button pinned to the trailing edge of the alert.
      # `ml-auto` right-aligns it: daisyUI's alert grid gives the last child an
      # `auto` column, so without it the button sits against the text.
      def close_button
        Bali::Button::Component.new(
          icon: "x",
          variant: :ghost,
          size: :sm,
          responsive: false,
          class: "btn-circle ml-auto alert-dismiss",
          data: { action: "alert#dismiss" },
          "aria-label": t(".close")
        )
      end

      def alert_classes
        class_names(
          BASE_CLASSES,
          COLORS.fetch(@color, COLORS[:neutral]),
          SIZES.fetch(@size, SIZES[:regular]),
          STYLES[@style]
        )
      end
    end
  end
end
