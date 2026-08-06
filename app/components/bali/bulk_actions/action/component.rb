# frozen_string_literal: true

module Bali
  module BulkActions
    module Action
      class Component < ApplicationViewComponent
        attr_reader :label, :href, :method, :variant, :size, :target

        # One table for every `.btn` in the library. See Bali::ButtonTaxonomy.
        VARIANTS = Bali::ButtonTaxonomy::VARIANTS
        SIZES = Bali::ButtonTaxonomy::SIZES

        CONTROL_ON_GET_MESSAGE = "BulkActions action %p declares `with_control` but uses " \
                                 "`method: :get`, which renders a link instead of a form: a " \
                                 "link has no form to carry the control's value, so it would " \
                                 "be submitted nowhere. Use the default `method: :post` (or " \
                                 "any other non-GET verb) for actions that take an input."

        # Un control del host que viaja con ESTA acción: un select de chofer, un date field,
        # lo que sea. Se renderiza DENTRO del `form_with` de la acción y antes del submit, así
        # que su valor viaja con el POST sin una línea de JS.
        #
        # OJO con los ids: el bloque es markup del host y dos acciones que monten el mismo
        # control repiten su id en el documento (el `label for=` se lo lleva el primero). Si
        # dos acciones comparten control, dale a cada una un `id:` propio — o `id: nil` si no
        # hay label que apuntar. Es el mismo gotcha que `preserved_params_hidden_fields`
        # resolvió con `id: nil` en Filters.
        renders_one :control

        # @param label [String] Texto del botón/enlace.
        # @param href [String] Destino de la acción.
        # @param method [Symbol] Verbo HTTP. `:get` renderiza un enlace; cualquier otro, un
        #   form propio con el hidden de ids seleccionados.
        # @param size [Symbol] Tamaño del botón. Lo inyecta la barra según su variante
        #   (`xs` en la fila contextual, `sm` en la flotante); pasarlo explícito gana.
        # @param target [String, Symbol] Contexto donde se abre la acción (`"_blank"` para
        #   imprimir en una pestaña nueva). En una acción-form va al `<form target>`; en una
        #   acción GET, al `<a target>`. Es opción de primera clase porque `form_with` solo
        #   respeta un puñado de opciones sueltas (`id`, `class`, `data`, ...) y se comía un
        #   `target:` pasado por **options sin decir nada.
        def initialize(label:, href:, method: :post, variant: :secondary, size: :sm,
                       target: nil, **options)
          @label = label
          @href = href
          @method = method.to_sym
          @variant = variant.to_sym
          @size = size.to_sym
          @target = target.presence
          @variant_class = Bali::ButtonTaxonomy.variant!(self.class, @variant)
          @size_class = Bali::ButtonTaxonomy.size!(self.class, @size)
          @options = options
        end

        def call
          # `with_control` se declara DENTRO del bloque de contenido de la acción, y un slot
          # declarado ahí no existe hasta que el bloque corre. Sin forzarlo, `control?` es
          # siempre `false` y el control desaparecía en silencio. `content` está memoizado,
          # así que esto lo evalúa UNA vez.
          content

          validate_control_method!

          if get_request?
            render_link_action
          else
            render_form_action
          end
        end

        private

        # Fail-fast, el patrón del repo (calca `resolve_simple_input` de Bali::FilterForm):
        # una acción GET con control renderiza un enlace que ignora el input, y el usuario
        # elige un valor que nunca llega al servidor. Silencioso y muy caro de diagnosticar.
        def validate_control_method!
          return unless get_request? && control?

          raise ArgumentError, format(CONTROL_ON_GET_MESSAGE, label)
        end

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
            **link_options
          )
        end

        def render_form_action
          helpers.form_with(url: href, method: method, class: "contents", **form_options) do |form|
            safe_join(
              [
                # `id: nil` porque cada acción es su propio form y todas emiten ESTE campo:
                # con el id derivado del name, una barra de tres acciones repetía
                # `id="selected_ids"` tres veces en el documento. El JS lo busca por su target
                # de Stimulus, no por id. Mismo arreglo que `preserved_params_hidden_fields`.
                form.hidden_field(:selected_ids, value: [], id: nil, data: bulk_action_data),
                control,
                form.submit(label, class: button_classes)
              ].compact
            )
          end
        end

        # `form_with` respeta `html:` para lo que no está en su lista corta de opciones
        # sueltas, y ahí es donde tiene que ir `target`.
        def form_options
          return @options if target.blank?

          @options.merge(html: (@options[:html] || {}).merge(target: target))
        end

        # `Link` splatea sus **options como atributos del `<a>`, así que `target` llega solo.
        def link_options
          return @options if target.blank?

          @options.merge(target: target)
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
