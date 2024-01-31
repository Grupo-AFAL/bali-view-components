# frozen_string_literal: true

module Bali
  module TreeView
    class Preview < ApplicationViewComponentPreview
      def default
        render(Bali::TreeView::Component.new(current_path: '/section-1')) do |c|
          c.with_item(name: 'Root', path: '/')
          c.with_item(name: 'Section 1', path: '/section-1') do |cc|
            cc.with_item(name: 'Page 1', path: '/section-1/page-1')
            cc.with_item(name: 'Page 2', path: '/section-1/page-2')
            cc.with_item(name: 'Page 3', path: '/section-1/page-3')
          end
          c.with_item(name: 'Section 2', path: '/section-2')
          c.with_item(name: 'Section 3', path: '/section-3')
        end
      end
    end
  end
end
