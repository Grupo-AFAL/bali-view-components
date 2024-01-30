# frozen_string_literal: true

module Bali
  module BulkActions
    class Preview < ApplicationViewComponentPreview
      RECORDS = [
        { id: 1, name: 'Name 1' },
        { id: 2, name: 'Name 2' },
        { id: 3, name: 'Name 3' }
      ].freeze

      def default
        render Bali::BulkActions::Component.new do |c|
          c.with_action(name: 'Archivar', href: '/table/bulk_action')

          RECORDS.each do |record|
            c.with_item(record_id: record[:id]) do
              safe_join([tag.p(record[:name])])
            end
          end
        end
      end
    end
  end
end
