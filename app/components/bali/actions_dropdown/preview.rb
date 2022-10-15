# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Preview < ApplicationViewComponentPreview
      def default
        render ActionsDropdown::Component.new do |c|
          c.safe_join([
                        c.render(Bali::Link::Component.new(
                                   name: 'Alta',
                                   icon_name: 'plus-circle',
                                   href: '#',
                                   drawer: true,
                                   class: 'dropdown-item'
                                 )),

                        c.tag.div(class: 'dropdown-divider'),

                        c.render(Bali::Link::Component.new(
                                   name: 'Exportar',
                                   icon_name: 'file-export',
                                   href: '#',
                                   drawer: true,
                                   class: 'dropdown-item'
                                 ))
                      ])
        end
      end
    end
  end
end
