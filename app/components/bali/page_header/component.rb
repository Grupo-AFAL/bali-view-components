# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      BASE_CLASSES = "page-header-component mb-4"
      # Mobile-first responsive: stack title/subtitle above actions instead of
      # relying on Level's max-sm:flex-wrap, which never fires because the left
      # side's flex-1 basis-0 contributes no width to the flex line (#625).
      RESPONSIVE_CLASSES = "max-sm:gap-3 max-sm:flex-col max-sm:items-stretch"

      # Under `sm` the back button takes a row of its own instead of standing in a
      # gutter beside the title. Inline it costs the title that gutter on every
      # wrapped line: at 375px the title got 291px of the 343px available and a
      # long one wrapped to three lines instead of two (#685).
      LEFT_CLASSES = "max-sm:w-full max-sm:flex-col max-sm:items-start max-sm:gap-2"

      # Maps PageHeader alignment values to Level alignment values
      ALIGNMENTS = {
        top: :start,
        center: :center,
        bottom: :end
      }.freeze

      BACK_BUTTON_CLASSES = "back-button btn btn-ghost size-9 text-primary"
      BACK_LABEL_KEY = "bali_view.page_header.back"

      # `tag:` is semantic only — the size lives here and does not follow the
      # heading level. Before v3 the slot derived the size from the tag, so the
      # `h1` this component now defaults to would have jumped from 24px to 36px
      # and the documented `tag: :h2` migration would have shrunk it again.
      TITLE_CLASSES = "title text-2xl font-bold"
      SUBTITLE_CLASSES = "subtitle text-sm text-base-content/60"

      # `flex-wrap` so the tags drop under the title instead of squeezing it:
      # unwrapped, two badges cut a 375px title down to 277px.
      TITLE_ROW_CLASSES = "page-header-title flex items-center gap-3 flex-wrap"
      TITLE_BLOCK_CLASSES = "page-header-title-block min-w-0 space-y-1"

      # The block form renders INSIDE the heading. Passing a heading of your own
      # nests one heading in another, which the HTML parser splits into an empty
      # heading plus yours — that was the second empty heading this component
      # used to emit.
      renders_one :title, ->(text = nil, tag: :h1, **options, &block) do
        heading_tag(text, tag, **prepend_class_name(options, TITLE_CLASSES), &block)
      end

      # `:p` and not a heading: the subtitle names nothing, it describes the
      # title. As an `h6` it opened a document section that has no content.
      renders_one :subtitle, ->(text = nil, tag: :p, **options, &block) do
        heading_tag(text, tag, **prepend_class_name(options, SUBTITLE_CLASSES), &block)
      end

      # Badges and status pills that belong to the title. Siblings of the
      # heading, not children of it: inside, they became part of its accessible
      # name ("The Matrix Action Released") and made it invalid HTML.
      renders_many :title_tags

      # `heading:` names the element of the constructor-provided `title:` — the same thing
      # the slot's `tag:` does, and like it, semantic only: the size stays TITLE_CLASSES.
      # It exists so the page components can lower the level contextually (#1055) without
      # giving up the shared classes that passing `title:` buys them.
      def initialize(title: nil, subtitle: nil, align: :center, back: nil, responsive: true,
                     heading: :h1, **options)
        @title = title
        @subtitle = subtitle
        @heading = heading
        @align = align.to_sym
        @back = back
        @responsive = responsive
        @options = options
      end

      private

      attr_reader :options

      def component_classes
        class_names(BASE_CLASSES, (@responsive ? RESPONSIVE_CLASSES : nil), options[:class])
      end

      def left_classes
        class_names("min-w-0", (@responsive ? LEFT_CLASSES : nil))
      end

      def level_align
        ALIGNMENTS.fetch(@align, :center)
      end

      # PageHeader es el último uso interno de Level, que queda deprecado en v3 (#684). El
      # aviso se silencia acá porque la decisión no es del host: sustituir el Level por flex
      # plano es trabajo del propio PageHeader, no de quien lo renderiza.
      def level_component
        Bali.deprecator.silence do
          Bali::Level::Component.new(align: level_align, class: component_classes,
                                     **options.except(:class))
        end
      end

      # Nothing to name, nothing to render. An `h1` (or the `h6` this used to
      # emit) with no text is an empty section in the document outline and an
      # axe violation, and every page without a subtitle emitted one.
      def title_element
        title || heading_tag(@title, @heading, class: TITLE_CLASSES)
      end

      def subtitle_element
        subtitle || (tag.p(@subtitle, class: SUBTITLE_CLASSES) if @subtitle.present?)
      end

      def title_row
        return @title_row if defined?(@title_row)

        heading = title_element
        @title_row =
          if title_tags.empty?
            heading
          else
            tag.div(class: TITLE_ROW_CLASSES) { safe_join([ heading, *title_tags ].compact) }
          end
      end

      def render_title_block?
        title_row.present? || subtitle_element.present?
      end

      def heading_tag(text, tag_name, **options, &block)
        return tag.send(tag_name, text, **options) if text.present?
        return unless block

        tag.send(tag_name, **options, &block)
      end

      def render_back_button?
        @back.present? && @back[:href].present?
      end

      # An icon-only link with no text is an anonymous node to a screen reader.
      # The label is skipped when the host passes a visible `name:`, so the
      # accessible name keeps matching the visible one.
      def back_button_options
        options = prepend_class_name(@back.dup.symbolize_keys, BACK_BUTTON_CLASSES)
        return options if options[:name].present? || options.key?(:"aria-label")

        options.merge("aria-label": I18n.t(BACK_LABEL_KEY))
      end
    end
  end
end
