# frozen_string_literal: true

module Bali
  module FormPage
    class Preview < ApplicationViewComponentPreview
      # `card: nil` is "let the context decide", and Lookbook params only carry strings.
      CARD_CHOICES = { "context" => nil, "true" => true, "false" => false }.freeze

      # @label Default
      # Form page wraps form content in a Card with consistent breadcrumbs and header.
      # Use for new/edit pages with a focused single-column form.
      def default
        render_with_template(template: "bali/form_page/previews/default")
      end

      # @label With Sidebar
      # Two-column layout: form on left, help/tips on right.
      def with_sidebar
        render_with_template(template: "bali/form_page/previews/with_sidebar")
      end

      # @label Page or drawer
      # ONE call site, two renders. `context: :auto` — the default — asks the host's
      # `Bali::LayoutConcern#drawer_request?` whether the Modal/Drawer is the one fetching this
      # view, so the same template serves a full page and an overlay with no `if` in it.
      #
      # A Lookbook preview cannot issue that request, and that is precisely what `:page` and
      # `:drawer` are for: forcing the variant is the only way the drawer render has visual
      # coverage here at all.
      #
      # `:drawer` drops the Card, the breadcrumbs and the back button — the last two are ways
      # OUT of a page, and a drawer is closed rather than left. `card:` is the escape hatch
      # that survives the context in either direction; for the other two the escape hatch is
      # `context: :page`, which restores the whole page chrome inside a drawer.
      # @param context select { choices: [auto, page, drawer] }
      # @param card select { choices: [context, true, false] }
      def page_or_drawer(context: :auto, card: "context")
        render_with_template(
          template: "bali/form_page/previews/context",
          locals: { context: context.to_sym, card: CARD_CHOICES.fetch(card.to_s) }
        )
      end
    end
  end
end
