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
        # @param select_all_filtered [Boolean] Lo inyecta la barra: cuando está disponible el
        #   modo "los N filtrados", la acción emite el hidden `select_all_filtered` que el JS
        #   voltea y re-emite los filtros vigentes. Sin él, el POST sale como salía siempre.
        # @param filter_params [Array<Array>] Pares `[name, value]` de los `q[...]` vigentes
        #   del listado. Viajan SIEMPRE que el modo esté disponible, esté activo o no: el
        #   flag es lo que le dice al servidor si tiene que mirarlos o quedarse con los ids.
        # @param target [String, Symbol] Contexto donde se abre la acción (`"_blank"` para
        #   imprimir en una pestaña nueva). En una acción-form va al `<form target>`; en una
        #   acción GET, al `<a target>`. Es opción de primera clase porque `form_with` solo
        #   respeta un puñado de opciones sueltas (`id`, `class`, `data`, ...) y se comía un
        #   `target:` pasado por **options sin decir nada.
        # rubocop:disable Metrics/ParameterLists
        def initialize(label:, href:, method: :post, variant: :secondary, size: :sm,
                       target: nil, select_all_filtered: false, filter_params: [], **options)
          # rubocop:enable Metrics/ParameterLists
          @label = label
          @href = href
          @select_all_filtered = select_all_filtered
          @filter_params = select_all_filtered ? Array(filter_params) : []
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
            href: link_href,
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
                select_all_filtered_field,
                filter_params_fields,
                control,
                form.submit(label, class: button_classes)
              ].compact
            )
          end
        end

        # El flag arranca en "false" y lo voltea el JS al entrar en el modo. Se emite siempre
        # (no `disabled` cuando está apagado) para que el POST tenga UNA forma sola: el
        # servidor lee el flag, no la ausencia de un campo.
        def select_all_filtered_field
          return unless @select_all_filtered

          helpers.hidden_field_tag(
            "select_all_filtered", "false",
            id: nil, data: { bulk_actions_target: "selectAllFilteredField" }
          )
        end

        # `id: nil` porque estos mismos campos se pintan en TODOS los forms de la barra.
        def filter_params_fields
          return if @filter_params.blank?

          safe_join(
            @filter_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
          )
        end

        # Una acción GET no tiene hidden fields donde meter los filtros, así que viajan en su
        # href. Los `q[...]` que ya trajera el href se descartan primero: el estado vigente
        # del listado es el que manda, y dos juegos de `q` en la misma URL se pisan de formas
        # que dependen del parser.
        def link_href
          return href if @filter_params.blank?

          uri = URI.parse(href.to_s)
          kept = Rack::Utils.parse_query(uri.query)
                            .reject { |name, _| name == "q" || name.start_with?("q[") }
                            .flat_map { |name, value| Array(value).map { |v| [ name, v ] } }
          uri.query = Rack::Utils.build_query(kept + @filter_params.map { |n, v| [ n.to_s, v.to_s ] })
          uri.to_s
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
