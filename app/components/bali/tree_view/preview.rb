# frozen_string_literal: true

module Bali
  module TreeView
    class Preview < ApplicationViewComponentPreview
      def default
        render(Bali::TreeView::Component.new(current_path: '/section-1')) do |c|
          c.item(name: 'Root', path: '/')
          c.item(name: 'Section 1', path: '/section-1') do |cc|
            cc.item(name: 'Page 1', path: '/section-1/page-1')
            cc.item(name: 'Page 2', path: '/section-1/page-2')
            cc.item(name: 'Page 3', path: '/section-1/page-3')
          end
          c.item(name: 'Section 2', path: '/section-2')
          c.item(name: 'Section 3', path: '/section-3')
        end
      end
    end
  end
end
