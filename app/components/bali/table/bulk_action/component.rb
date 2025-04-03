# frozen_string_literal: true

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
          options[:class] ||= 'button is-ghost'

          if method == :get
            options[:data] ||= {}
            options[:data][:table_target] = 'bulkAction'

            render(Bali::Link::Component.new(name: name, href: href, method: method, **options))
          else
            form_with(url: href, method: method) do |form|
              safe_join(
                [
                  form.hidden_field(:selected_ids, value: [], data: { table_target: 'bulkAction' }),
                  form.submit(name, **options)
                ]
              )
            end
          end
        end
      end
    end
  end
end
