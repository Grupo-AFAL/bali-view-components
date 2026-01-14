# frozen_string_literal: true

module Bali
  module BulkActions
    class Preview < ApplicationViewComponentPreview
      RECORDS = [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
        { id: 3, name: 'Bob Wilson', email: 'bob@example.com' }
      ].freeze

      def default
        render Bali::BulkActions::Component.new do |c|
          c.with_action(name: 'Archive', href: '/users/bulk_archive')
          c.with_action(name: 'Delete', href: '/users/bulk_delete')

          RECORDS.each do |record|
            c.with_item(record_id: record[:id], class: 'flex items-center gap-3 p-3 rounded-lg hover:bg-base-200') do
              safe_join([
                tag.input(type: 'checkbox', class: 'checkbox checkbox-sm'),
                tag.div(class: 'flex-1') do
                  safe_join([
                    tag.p(record[:name], class: 'font-medium'),
                    tag.p(record[:email], class: 'text-sm text-base-content/60')
                  ])
                end
              ])
            end
          end
        end
      end
    end
  end
end
