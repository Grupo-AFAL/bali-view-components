# frozen_string_literal: true

module Bali
  module Topbar
    module ToolsMenu
      # The topbar's internal tools menu: jobs panel, dashboards, mailbox, repository,
      # monitoring. It goes in `Bali::Topbar`'s `with_action` slot.
      #
      # It receives the tools ALREADY FILTERED BY PERMISSION. The gem does not evaluate
      # permissions: the hosts that use it share no authorization vocabulary (some have
      # named permissions, others policies), and leaving that decision outside is what lets
      # the same component serve all of them with no special cases.
      #
      # What the component does decide is what exists in THIS environment, by asking its own
      # view context (see `Tool#available?`). If none is left it does not render: a trigger
      # that opens an empty panel is worse than not having one.
      class Component < ApplicationViewComponent
        # @param tools [Array<Tool>] already filtered by permission.
        # @param icon [String] the trigger's icon.
        # @param aria_label [String, nil] accessible name of the trigger; the translated one
        #   by default. It is icon-only: with no accessible name it has no name.
        # @param align [Symbol] horizontal axis of the dropdown.
        def initialize(tools:, icon: "wrench", aria_label: nil, align: :end, **options)
          @tools = Array(tools)
          @icon = icon
          @aria_label = aria_label
          @align = align
          @options = options
        end

        def render?
          visible_tools.any?
        end

        # `helpers` is the view context of the render in progress: the collaborator we
        # already have, instead of reaching for `Rails.application`.
        def visible_tools
          @visible_tools ||= @tools.select { |tool| tool.available?(helpers) }
        end

        def href_for(tool)
          tool.href(helpers)
        end

        # Explicit `name:` → host key → gem key → humanize.
        def label_for(tool)
          return tool.name if tool.name.present?

          t("topbar.tools_menu.items.#{tool.key}",
            default: [ :"bali_view.topbar.tools_menu.items.#{tool.key}", tool.key.to_s.humanize ])
        end

        # Host key → gem key. The same pattern as `label_for`, so that whoever learns the
        # override on the items finds it on the trigger too.
        def trigger_label
          @aria_label ||
            t("topbar.tools_menu.trigger_label", default: :"bali_view.topbar.tools_menu.trigger_label")
        end

        def link_options(tool)
          return {} unless tool.new_tab?

          { target: "_blank", rel: "noopener" }
        end

        def dropdown_options
          @options.merge(
            align: @align,
            class: class_names("bali-topbar-tools-menu", @options[:class])
          )
        end

        attr_reader :icon
      end
    end
  end
end
