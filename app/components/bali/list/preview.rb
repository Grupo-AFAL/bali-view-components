# frozen_string_literal: true

module Bali
  module List
    class Preview < ApplicationViewComponentPreview
      def default
        render List::Component.new do |c|
          c.item do |i|
            i.title('Primer elemento')
            i.subtitle('Descripción primer elemento')
          end
          c.item do |i|
            i.title('Segundo elemento con **options', class: 'has-text-success')
            i.subtitle('Descripción segundo elemento')
          end
          c.item do |i|
            i.title do
              tag.a 'Tercero con un link', href: '#'
            end
            i.subtitle do
              tag.p('Descripción tercer elemento con bloque', class: 'has-text-info')
            end
          end
        end
      end

      def with_actions
        render List::Component.new do |c|
          c.item do |i|
            i.title('Primer elemento')
            i.subtitle('Descripción primer elemento')
            i.actions do
              c.render(Bali::Icon::Component.new('trash'))
            end
          end

          c.item do |i|
            i.title('segundo elemento')
            i.subtitle('Descripción segundo elemento')
            i.actions do
              c.render(Bali::Icon::Component.new('trash'))
            end
          end
        end
      end
    end
  end
end
