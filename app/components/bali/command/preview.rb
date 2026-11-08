# frozen_string_literal: true

module Bali
  module Command
    class Preview < ApplicationViewComponentPreview
      # The `locale:` keywords below go unread: the dummy's ComponentPreviewsController
      # applies `?locale=` to the whole request. Lookbook raises "Unknown method parameter" for an
      # `@param` the method does not take.

      # @label Default
      # Command palette with grouped pages, recents, and quick actions.
      # The search-well trigger is the component's own default — no slot needed.
      # Click it or press ⌘K (Mac) / Ctrl+K to open — and the hint on the
      # trigger says whichever of the two this machine actually has.
      # The footer is Bali's translation: switch `locale` to see it.
      # @param locale select { choices: [en, es] }
      def default(locale: "en")
        render_with_template(template: "bali/command/previews/default")
      end

      # @label Compact density
      # Tighter rows for power users / dense workspaces. Its one action row is
      # the only result on open, so the footer counts it in the singular.
      # @param locale select { choices: [en, es] }
      def compact(locale: "en")
        render_with_template(template: "bali/command/previews/compact")
      end

      # @label From a navigation
      # `navigation:` adds the frequent pages the person may open, listed on open — Projects, Inbox
      # and Users are `frequent: true` —, then the modules and every page they may open, found as
      # you type by its title, group, section, module or hint. The block's groups follow — here a
      # create action. The navigation is the side menu preview's,
      # `Bali::SideMenu::Preview::DemoNavigation`: «Exports» is `menu: false`, so it is found here
      # and not drawn there. See docs/guides/navigation.md.
      #
      # ```erb
      # <%= render Bali::Command::Component.new(navigation: Navigation) %>
      # ```
      def from_navigation
        render_with_template(template: "bali/command/previews/from_navigation")
      end

      # @label Custom trigger
      # The `with_trigger` slot replaces the default search well — for shapes
      # the default cannot be, like an icon-only toolbar button. The slot
      # content is the whole trigger: bring your own accessible name.
      def custom_trigger
        render_with_template(template: "bali/command/previews/custom_trigger")
      end
    end
  end
end
