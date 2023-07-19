module Bali
  module Table
    module BulkAction
      class Component < ApplicationViewComponent
        attr_reader :name, :href, :method, :options

        def initialize(name:, href:, method: :post, **options)
          @name = name
          @href = href
          @method = method&.to_sym
          @options = options
        end

        def call
          form_with(url: href, method: method, **options) do |form|
            safe_join(
              [
                form.hidden_field(:selected_ids, value: [], data: { table_target: 'bulkAction' }),
                form.submit(name, class: 'button')
              ]
            )
          end
        end
      end
    end
  end
end
