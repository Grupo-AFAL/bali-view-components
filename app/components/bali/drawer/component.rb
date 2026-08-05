# frozen_string_literal: true

module Bali
  module Drawer
    class Component < ApplicationViewComponent
      SIZES = {
        sm: "max-w-sm",
        md: "max-w-lg",
        lg: "max-w-2xl",
        xl: "max-w-4xl",
        full: "max-w-full"
      }.freeze

      # Tailwind safelist: group-[.drawer-open]:translate-x-0
      # Tailwind safelist: max-md:group-[.drawer-open]:max-w-[85%]
      POSITIONS = {
        left: { side: "left-0", transform: "-translate-x-full",
                open_class: "group-[.drawer-open]:translate-x-0" },
        right: { side: "right-0", transform: "translate-x-full",
                 open_class: "group-[.drawer-open]:translate-x-0" }
      }.freeze

      renders_one :header
      renders_one :footer

      attr_reader :drawer_id

      # @param shared [Boolean] Whether this drawer answers a `drawer#open` trigger that
      #   names no drawer. See {#shared?}.
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        active: false,
        size: :md,
        position: :right,
        drawer_id: nil,
        title: nil,
        confirm_close_message: nil,
        dismissable_without_confirm: false,
        shared: true,
        **options
      )
        @active = active
        @size = size&.to_sym
        @position = position&.to_sym
        @drawer_id = drawer_id || "drawer-#{SecureRandom.hex(4)}"
        @title = title
        @confirm_close_message = confirm_close_message
        @dismissable_without_confirm = dismissable_without_confirm
        @shared = shared
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def drawer_classes
        class_names(
          "drawer-component group z-[var(--bali-z-drawer)] fixed",
          @active && "drawer-open",
          @options[:class]
        )
      end

      def panel_classes
        position_config = position_settings

        class_names(
          "drawer-panel",
          "fixed top-0 h-full w-full",
          position_config[:side],
          SIZES.fetch(@size, SIZES[:md]),
          "bg-base-100 shadow-2xl",
          "transform transition-transform duration-300 ease-in-out",
          position_config[:transform],
          "overflow-auto z-10"
        )
      end

      def panel_open_class
        position_settings[:open_class]
      end

      def title_id
        "#{drawer_id}-title"
      end

      def title?
        @title.present? || header?
      end

      def close_button_label
        t(".close_drawer")
      end

      # A `drawer#open` trigger may name the drawer it opens (`data-drawer-id`), and
      # usually does not — the common page has one shared overlay and the event is a
      # broadcast. A shared drawer answers those broadcasts; a drawer that belongs to one
      # feature and has its own trigger sets `shared: false` and only ever opens when
      # something names it.
      #
      # It matters because the package itself ships a second drawer:
      # `Bali::FeedbackWidget`. With every drawer answering every broadcast, one click on
      # an ordinary "New…" trigger opened both it and the layout's drawer. Only the one
      # holding the submitted form gets closed afterwards, and the other stays
      # `showModal()`-ed — a `<dialog>` in the top layer makes the entire document outside
      # it inert, so the page went on looking normal and stopped answering the mouse
      # (#854).
      def shared?
        @shared
      end

      # Confirm-on-close is on by default: an unsaved form inside the drawer
      # prompts before Escape/overlay/close-button discard the input. Opt out
      # per-drawer with `dismissable_without_confirm: true`.
      def confirm_close?
        !@dismissable_without_confirm
      end

      def confirm_close_message
        @confirm_close_message.presence || t(".confirm_close")
      end

      private

      attr_reader :title, :options

      def position_settings
        POSITIONS.fetch(@position, POSITIONS[:right])
      end

      def html_attributes
        {
          id: drawer_id,
          class: drawer_classes,
          'aria-labelledby': title? ? title_id : nil,
          data: default_data_attributes.merge(options.fetch(:data, {}))
        }.compact
      end

      def default_data_attributes
        {
          controller: "drawer",
          drawer_target: "template",
          action: "keydown.esc->drawer#close"
        }.merge(confirm_close_data_attributes).merge(shared_data_attributes)
      end

      # Only written when it is false: the Stimulus value already defaults to true, so
      # every ordinary drawer keeps the markup it had.
      def shared_data_attributes
        return {} if shared?

        { drawer_shared_value: false }
      end

      def confirm_close_data_attributes
        return {} unless confirm_close?

        { drawer_confirm_close_message_value: confirm_close_message }
      end
    end
  end
end
