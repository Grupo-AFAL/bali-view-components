# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      # @param title text
      def default(title: 'Title')
        render PageHeader::Component.new(title: title) do
          tag.a 'Right action', class: 'btn btn-secondary', href: '#'
        end
      end

      # @param title text
      def without_right_content(title: 'Title')
        render PageHeader::Component.new(title: title)
      end

      # @param title text
      # @param subtitle text
      # @param align select ['top', 'center', 'bottom']
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
        render PageHeader::Component.new(title: title, subtitle: subtitle) do
          tag.a 'Right action', class: 'btn btn-secondary', href: '#'
        end
      end

      # @param title text
      # @param subtitle text
      # @param title_tag select ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']
      # @param subtitle_tag select ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']
      # @param title_class select ['text-info', 'text-success', 'text-warning']
      # @param subtitle_class select ['text-primary', 'text-error', 'text-secondary']
      def with_title_and_subtitle_as_slots(
        title: 'Title', title_tag: :h3, title_class: 'text-info',
        subtitle: 'Subtitle', subtitle_tag: :h5, subtitle_class: 'text-primary'
      )
        render PageHeader::Component.new do |c|
          c.with_title(title, tag: title_tag, class: title_class)
          c.with_subtitle(subtitle, tag: subtitle_tag, class: subtitle_class)

          tag.a 'Right action', class: 'btn btn-secondary', href: '#'
        end
      end

      # @param title text
      # @param subtitle text
      def with_title_and_subtitle_as_block(title: 'Title', subtitle: 'Subtitle')
        render PageHeader::Component.new do |c|
          c.with_title { tag.h3(title, class: 'text-2xl font-bold') }
          c.with_subtitle { tag.h5(subtitle, class: 'text-lg text-base-content/60') }

          tag.a 'Right action', class: 'btn btn-secondary', href: '#'
        end
      end
    end
  end
end
