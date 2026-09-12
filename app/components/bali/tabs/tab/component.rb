# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
        # Keyed by Bali::Color::NAMES; the values are spelled out because Tailwind
        # only emits a class it can find as a literal string in a source file.
        COUNT_COLORS = {
          neutral: "badge-neutral",
          primary: "badge-primary",
          secondary: "badge-secondary",
          accent: "badge-accent",
          info: "badge-info",
          success: "badge-success",
          warning: "badge-warning",
          error: "badge-error",
          ghost: "badge-ghost"
        }.freeze

        # Public accessors needed by Trigger::Component
        attr_reader :active, :icon, :title, :src, :reload, :href, :count, :turbo_action,
                    :options, :explicit_active

        # @param active [Boolean] Whether the tab is active
        # @param icon [String] The name of the icon to use
        # @param title [String] The title of the tab
        # @param src [String] Hyperlink to the tab content
        # @param reload [Boolean] Whether the tab content should be reloaded
        #                             when the tab is clicked
        # @param href [String] Full page navigation URL (mutually exclusive with src)
        # @param count [Integer, String] Renders a count badge after the title
        #   ("99+" works too). `nil` renders nothing; `0` renders — an empty
        #   inbox is information.
        # @param count_color [Symbol] Semantic color for the count badge, from
        #   the same table every other `color:` takes. A count is sometimes an
        #   alarm, not just an amount — "3 blocking questions" should not look
        #   like "3 items". `nil` keeps today's neutral badge.
        # @param turbo_action [Symbol, false] Navigation mode only: value of
        #   `data-turbo-action` on the link, `:advance` by default so tabs that
        #   navigate inside a turbo frame still update the URL. Pass `false` to
        #   omit the attribute.
        # rubocop:disable Metrics/ParameterLists
        def initialize(active: NOT_PROVIDED, icon: nil, title: "", src: nil, reload: false,
                       href: nil, count: nil, count_color: nil, turbo_action: :advance, **options)
          @explicit_active = active != NOT_PROVIDED
          @active = @explicit_active ? active : false
          @icon = icon
          @title = title
          @src = src
          @reload = reload
          @href = href
          @count = count
          @count_color = Bali::Color.name!(self.class, count_color, param: :count_color)
          @turbo_action = turbo_action

          @options = options.except(:href)
        end
        # rubocop:enable Metrics/ParameterLists

        NOT_PROVIDED = Object.new.freeze
        private_constant :NOT_PROVIDED

        def count_color_class
          COUNT_COLORS[@count_color]
        end

        # Panel mode: the tab options land on the `role="tabpanel"` div, which
        # starts hidden unless the tab is active. Navigation mode reads
        # `options` raw instead — the `<a>` must not start hidden.
        def panel_options
          @panel_options ||= active ? options : prepend_class_name(options.dup, "hidden")
        end

        def call
          content
        end
      end
    end
  end
end
