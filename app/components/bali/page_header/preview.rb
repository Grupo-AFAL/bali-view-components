# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      def default
        render PageHeader::Component.new(title: 'Title') do |c|
          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      def without_right_content
        render PageHeader::Component.new(title: 'Title')
      end

      def with_subtitle_as_param
        render PageHeader::Component.new(title: 'Title', subtitle: 'Subtitle') do |c|
          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      def with_title_and_subtitle_as_slots
        render PageHeader::Component.new do |c|
          c.title('Title', class: 'title is-3')
          c.subtitle('Subtitle', class: 'subtitle is-6')

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end

      def with_title_and_subtitle_as_block
        render PageHeader::Component.new do |c|
          c.title { tag.h1('Title', class: 'title is-3') }
          c.subtitle { tag.h1('Subtitle', class: 'subtitle is-6') }

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end
    end
  end
end
