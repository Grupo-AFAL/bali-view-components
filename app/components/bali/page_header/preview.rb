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

      # @param title text
      # @param subtitle text
      # @param title_tag select { choices: [h1, h2, h3, h4, h5, h6] }
      # @param subtitle_tag select { choices: [h1, h2, h3, h4, h5, h6] }
      # @param title_class select { choices: [text-info, text-success, text-warning] }
      # @param subtitle_class select { choices: [text-primary, text-error, text-secondary] }
      def with_title_and_subtitle_as_slots(
        title: 'Title', title_tag: :h3, title_class: 'text-info',
        subtitle: 'Subtitle', subtitle_tag: :h5, subtitle_class: 'text-primary'
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

      # @param title text
      # @param subtitle text
      def with_title_and_subtitle_as_block(title: 'Title', subtitle: 'Subtitle')
        render_with_template(locals: { title: title, subtitle: subtitle })
      end
    end
  end
end
