# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      # @param title text
      def default(title: 'Title')
        render PageHeader::Component.new(title: title) do
          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      # @param title text
      def without_right_content(title: 'Title')
        render PageHeader::Component.new(title: title)
      end

      # @param title text
      # @param subtitle text
      def with_subtitle_as_param(title: 'Title', subtitle: 'Subtitle')
        render PageHeader::Component.new(title: title, subtitle: subtitle) do
          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      # @param title text
      # @param subtitle text
      # @param title_tag select ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']
      # @param subtitle_tag select ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']
      # @param title_class select ['has-text-info', 'has-text-success', 'has-text-warning']
      # @param subtitle_class select ['has-text-primary', 'has-text-danger', 'has-text-link']
      def with_title_and_subtitle_as_slots(
        title: 'Title', title_tag: :h3, title_class: 'has-text-info',
        subtitle: 'Subtitle', subtitle_tag: :h5, subtitle_class: 'has-text-primary'
      )
        render PageHeader::Component.new do |c|
          c.title(title, tag: title_tag, class: title_class)
          c.subtitle(subtitle, tag: subtitle_tag, class: subtitle_class)

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      # @param title text
      # @param subtitle text
      def with_title_and_subtitle_as_block(title: 'Title', subtitle: 'Subtitle')
        render PageHeader::Component.new do |c|
          c.title { tag.h3(title, class: 'title is-3') }
          c.subtitle { tag.h5(subtitle, class: 'subtitle is-5') }

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end
    end
  end
end
