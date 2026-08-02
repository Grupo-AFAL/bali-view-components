# frozen_string_literal: true

module Bali
  module BulkActions
    module Action
      class Component < ApplicationViewComponent
        attr_reader :label, :href, :method, :variant, :size

        # One table for every `.btn` in the library. See Bali::ButtonTaxonomy.
        VARIANTS = Bali::ButtonTaxonomy::VARIANTS
        SIZES = Bali::ButtonTaxonomy::SIZES

        # @param size [Symbol] Tamaño del botón. Lo inyecta la barra según su variante
        #   (`xs` en la fila contextual, `sm` en la flotante); pasarlo explícito gana.
        def initialize(label:, href:, method: :post, variant: :secondary, size: :sm, **options)
          @label = label
          @href = href
          @method = method.to_sym
          @variant = variant.to_sym
          @size = size.to_sym
          @variant_class = Bali::ButtonTaxonomy.variant!(self.class, @variant)
          @size_class = Bali::ButtonTaxonomy.size!(self.class, @size)
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
            variant: variant,
            size: size,
            data: { bulk_actions_target: "bulkAction" },
            **@options
          )
        end

        def render_form_action
          helpers.form_with(url: href, method: method, class: "contents", **@options) do |form|
            safe_join(
              [
                form.hidden_field(:selected_ids, value: [], data: bulk_action_data),
                form.submit(label, class: button_classes)
              ]
            )
          end
        end

        def bulk_action_data
          { bulk_actions_target: "bulkAction" }
        end

        # `"btn-#{size}"` was invisible to Tailwind's scanner: the class only ever shipped
        # because some other component happened to spell it out.
        def button_classes
          class_names("btn", @size_class, @variant_class)
        end
      end
    end
  end
end
