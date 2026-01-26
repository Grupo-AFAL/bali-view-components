# frozen_string_literal: true

module Bali
  module BulkActions
    module Action
      class Component < ApplicationViewComponent
        attr_reader :label, :href, :method, :variant

        VARIANTS = {
          primary: 'btn-primary',
          secondary: 'btn-secondary',
          accent: 'btn-accent',
          info: 'btn-info',
          success: 'btn-success',
          warning: 'btn-warning',
          error: 'btn-error',
          ghost: 'btn-ghost',
          neutral: 'btn-neutral'
        }.freeze

        def initialize(label:, href:, method: :post, variant: :secondary, **options)
          @label = label
          @href = href
          @method = method.to_sym
          @variant = variant.to_sym
          @options = options
        end

        def call
          if get_request?
            render_link_action
          else
            render_form_action
          end
        end

        private

        def get_request?
          method == :get
        end

        def render_link_action
          render Bali::Link::Component.new(
            name: label,
            href: href,
            type: variant,
            size: :sm,
            data: { bulk_actions_target: 'bulkAction' },
            **@options
          )
        end

        def render_form_action
          helpers.form_with(url: href, method: method, class: 'contents', **@options) do |form|
            safe_join(
              [
                form.hidden_field(:selected_ids, value: [], data: bulk_action_data),
                form.submit(label, class: button_classes)
              ]
            )
          end
        end

        def bulk_action_data
          { bulk_actions_target: 'bulkAction' }
        end

        def button_classes
          class_names('btn btn-sm', VARIANTS[variant])
        end
      end
    end
  end
end
