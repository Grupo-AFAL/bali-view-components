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
      def with_title_and_subtitle_as_slots(title: 'Title', subtitle: 'Subtitle')
        render PageHeader::Component.new do |c|
          c.title(title, class: 'title is-3')
          c.subtitle(subtitle, class: 'subtitle is-6')

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      # @param title text
      # @param subtitle text
      def with_title_and_subtitle_as_block(title: 'Title', subtitle: 'Subtitle')
        render PageHeader::Component.new do |c|
          c.title { tag.h1(title, class: 'title is-3') }
          c.subtitle { tag.p(subtitle, class: 'subtitle is-6') }

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end
    end
  end
end
