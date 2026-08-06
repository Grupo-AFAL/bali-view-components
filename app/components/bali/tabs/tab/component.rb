# frozen_string_literal: true

module Bali
  module Tabs
    module Tab
      class Component < ApplicationViewComponent
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
        # @param turbo_action [Symbol, false] Navigation mode only: value of
        #   `data-turbo-action` on the link, `:advance` by default so tabs that
        #   navigate inside a turbo frame still update the URL. Pass `false` to
        #   omit the attribute.
        # rubocop:disable Metrics/ParameterLists
        def initialize(active: NOT_PROVIDED, icon: nil, title: "", src: nil, reload: false,
                       href: nil, count: nil, turbo_action: :advance, **options)
          @explicit_active = active != NOT_PROVIDED
          @active = @explicit_active ? active : false
          @icon = icon
          @title = title
          @src = src
          @reload = reload
          @href = href
          @count = count
          @turbo_action = turbo_action

          @options = options.except(:href)
        end
        # rubocop:enable Metrics/ParameterLists

        NOT_PROVIDED = Object.new.freeze
        private_constant :NOT_PROVIDED

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
