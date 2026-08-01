# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      # @param title text
      def default(title: 'Title')
        render_with_template(locals: { title: title })
      end

      # @param title text
      def without_right_content(title: 'Title')
        render PageHeader::Component.new(title: title)
      end

      # The back link is icon-only, so it carries an `aria-label` from
      # `bali_view.page_header.back`. Pass `back: { name: 'Back to movies' }`
      # for a visible label instead, or your own `'aria-label':` to override it.
      #
      # @param title text
      # @param subtitle text
      # @param align select { choices: [top, center, bottom] }
      def with_back_button(title: 'Title', subtitle: 'Subtitle', align: :top)
        render PageHeader::Component.new(
          title: title,
          subtitle: subtitle,
          align: align.to_sym,
          back: { href: '#' }
        )
      end

      # @param title text
      # @param subtitle text
      def with_subtitle_as_param(title: 'Title', subtitle: 'Subtitle')
        render_with_template(locals: { title: title, subtitle: subtitle })
      end

      # Tags render as SIBLINGS of the heading, so they stay out of its
      # accessible name, and the row wraps: on a narrow viewport they drop below
      # the title instead of squeezing it.
      #
      # @param title text
      def with_title_tags(title: 'The Matrix Reloaded: Special Extended Edition')
        render_with_template(locals: { title: title })
      end

      # `tag:` is semantic only — it sets the element, never the size. Use
      # `class:` for the size. The title defaults to `h1`; pass `tag: :h2` when
      # the surrounding layout already owns the page's `h1`.
      #
      # @param title text
      # @param subtitle text
      # @param title_tag select { choices: [h1, h2, h3, h4, h5, h6] }
      # @param subtitle_tag select { choices: [p, h2, h3, h4, h5, h6] }
      # @param title_class select { choices: [text-info, text-success, text-warning] }
      # @param subtitle_class select { choices: [text-primary, text-error, text-secondary] }
      def with_title_and_subtitle_as_slots(
        title: 'Title', title_tag: :h1, title_class: 'text-info',
        subtitle: 'Subtitle', subtitle_tag: :p, subtitle_class: 'text-primary'
      )
        render_with_template(locals: {
          title: title,
          title_tag: title_tag,
          title_class: title_class,
          subtitle: subtitle,
          subtitle_tag: subtitle_tag,
          subtitle_class: subtitle_class
        })
      end

      # The block is the CONTENT of the heading. A heading inside the block
      # nests one heading in another, and the parser splits that into an empty
      # heading plus yours.
      #
      # @param title text
      # @param subtitle text
      def with_title_and_subtitle_as_block(title: 'Title', subtitle: 'Subtitle')
        render_with_template(locals: { title: title, subtitle: subtitle })
      end
    end
  end
end
