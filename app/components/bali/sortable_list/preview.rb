# frozen_string_literal: true

module Bali
  module SortableList
    class Preview < ApplicationViewComponentPreview
      def default(disabled: false, update_url: '/sortable_list')
        render SortableList::Component.new(disabled: disabled) do |s|
          5.times do |i|
            s.item(update_url: update_url) { "Item #{i}" }
          end
        end
      end

      def with_handle(disabled: false, update_url: '/sortable_list', handle: '.handle')
        handle_class = handle.gsub(/\./, '')

        render_with_template(
          template: 'bali/sortable_list/previews/with_handle',
          locals: {
            disabled: disabled,
            handle: handle,
            handle_class: handle_class,
            update_url: update_url
          }
        )
      end

      def shared(group_name: 'shared', update_url: '/sortable_list', disabled: false)
        render_with_template(
          template: 'bali/sortable_list/previews/shared',
          locals: {
            disabled: disabled,
            group_name: group_name,
            update_url: update_url
          }
        )
      end

      def nested(disabled: false, group_name: 'nested', update_url: '/sortable_list')
        render_with_template(
          template: 'bali/sortable_list/previews/nested',
          locals: {
            disabled: disabled,
            group_name: group_name,
            update_url: update_url
          }
        )
      end
    end
  end
end
