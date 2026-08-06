# frozen_string_literal: true

module Bali
  module BulkActions
    class Preview < ApplicationViewComponentPreview
      RECORDS = [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
        { id: 3, name: 'Bob Wilson', email: 'bob@example.com' }
      ].freeze

      DRIVERS = [['Ana Ruiz', 1], ['Beto Lara', 2], ['Carla Díaz', 3]].freeze

      # Click on items to select them. The floating action bar appears when items are selected.
      def default
        render Bali::BulkActions::Component.new do |c|
          c.with_action(label: 'Archive', href: '/users/bulk_archive', variant: :info)
          c.with_action(label: 'Delete', href: '/users/bulk_delete', variant: :error)

          RECORDS.each { |record| item_for(c, record) }
        end
      end

      # `variant: :toolbar` renders the contextual row a DataTable puts where its toolbar
      # sits, instead of the floating bar. Click on items to select them.
      def toolbar
        render Bali::BulkActions::Component.new(variant: :toolbar) do |c|
          c.with_action(label: 'Archive', href: '/users/bulk_archive', variant: :info)
          c.with_action(label: 'Delete', href: '/users/bulk_delete', variant: :error)

          RECORDS.each { |record| item_for(c, record) }
        end
      end

      # @label Control and target
      # Two things an action can carry beyond the selected ids:
      #
      # - **`with_control`** mounts host markup INSIDE the action's own `<form>`, right before
      #   the submit, so its value is posted together with `selected_ids` — no JavaScript.
      #   Give each control an explicit `id:` (or `id: nil`) when two actions mount the same
      #   widget: ids have to stay unique in the document.
      # - **`target:`** picks the browsing context. `"_blank"` is the "print in a new tab"
      #   case: the listing keeps its selection because the page never navigates.
      #
      # A control on a `method: :get` action raises `ArgumentError`: a GET action renders a
      # link, and a link has no form to carry the value anywhere.
      #
      # **Nesting**: every action is its own `<form>`. If your listing already lives inside a
      # form of yours, the browser hoists the inner one out and the action silently stops
      # working — render that form outside the listing and point a submit at it with the HTML
      # `form="its-id"` attribute.
      def control_and_target
        render Bali::BulkActions::Component.new(variant: :toolbar) do |c|
          c.with_action(label: 'Assign driver', href: '/shipments/bulk_assign',
                        variant: :primary) do |action|
            action.with_control do
              tag.select(name: 'driver_id', class: 'select select-xs w-40', 'aria-label': 'Driver') do
                safe_join(DRIVERS.map { |name, id| tag.option(name, value: id) })
              end
            end
          end
          c.with_action(label: 'Print', href: '/shipments/bulk_print', variant: :secondary,
                        target: '_blank')

          RECORDS.each { |record| item_for(c, record) }
        end
      end

      private

      def item_for(component, record)
        component.with_item(record_id: record[:id],
                            class: 'flex items-center gap-3 p-3 rounded-lg hover:bg-base-200') do
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
