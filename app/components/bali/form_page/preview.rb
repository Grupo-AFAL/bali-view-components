# frozen_string_literal: true

module Bali
  module FormPage
    class Preview < ApplicationViewComponentPreview
      # `card: nil` is "let the context decide", and Lookbook params only carry strings.
      CARD_CHOICES = { "context" => nil, "true" => true, "false" => false }.freeze

      # Same contract for the heading level: `nil` is contextual (`h1` page / `h2` drawer).
      HEADING_CHOICES = { "context" => nil, "h1" => :h1, "h2" => :h2, "h3" => :h3 }.freeze

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
      # OUT of a page, and a drawer is closed rather than left — and lowers the title from
      # `h1` to `h2`, because the page underneath keeps the document's `h1` (#1055). `card:`
      # and `heading:` are the escape hatches that survive the context in either direction;
      # for the other two the escape hatch is `context: :page`, which restores the whole page
      # chrome inside a drawer.
      # @param context select { choices: [auto, page, drawer] }
      # @param card select { choices: [context, true, false] }
      # @param heading select { choices: [context, h1, h2, h3] }
      def page_or_drawer(context: :auto, card: "context", heading: "context")
        render_with_template(
          template: "bali/form_page/previews/context",
          locals: {
            context: context.to_sym,
            card: CARD_CHOICES.fetch(card.to_s),
            heading: HEADING_CHOICES.fetch(heading.to_s)
          }
        )
      end
    end
  end
end
