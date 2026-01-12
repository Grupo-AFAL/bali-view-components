# frozen_string_literal: true

module Bali
  module List
    class Preview < ApplicationViewComponentPreview
      def default
        render List::Component.new do |c|
          c.with_item do |i|
            i.with_title('Primer elemento')
            i.with_subtitle('Descripción primer elemento')
          end
          c.with_item do |i|
            i.with_title('Segundo elemento con **options', class: 'text-success')
            i.with_subtitle('Descripción segundo elemento')
          end
          c.with_item do |i|
            i.with_title do
              tag.a 'Tercero con un link', href: '#'
            end
            i.with_subtitle do
              tag.p('Descripción tercer elemento con bloque', class: 'text-info')
            end
          end
        end
      end

      def with_actions
        render List::Component.new do |c|
          c.with_item do |i|
            i.with_title('Primer elemento')
            i.with_subtitle('Descripción primer elemento')
            i.with_action do
              c.render(Bali::Icon::Component.new('trash'))
            end
          end

          c.with_item do |i|
            i.with_title('segundo elemento')
            i.with_subtitle('Descripción segundo elemento')
            i.with_action do
              c.render(Bali::Icon::Component.new('trash'))
            end
          end
        end
      end

      def with_content
        render List::Component.new do |c|
          c.with_item do |i|
            i.with_title('Primer elemento')
            i.with_subtitle('Descripción primer elemento')
            i.with_action do
              c.render(Bali::Icon::Component.new('trash'))
            end

            tag.p('Aditional content')
          end

          c.with_item do |i|
            i.with_title('segundo elemento')
            i.with_subtitle('Descripción segundo elemento')
            i.with_action do
              c.render(Bali::Icon::Component.new('trash'))
            end

            tag.p('Aditional content')
          end
        end
      end
    end
  end
end
