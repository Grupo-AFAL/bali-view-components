# frozen_string_literal: true

module Bali
  module BulkActions
    class Component < ApplicationViewComponent
      # El tamaño de los botones lo decide la BARRA, no quien declara la acción: en la fila
      # contextual los botones van DENTRO de una superficie tintada de alto fijo, así que un
      # `sm` (32px, el alto exacto de la barra) queda a ras de los bordes y se ve apretado.
      # `xs` (24px) deja 4px de aire arriba y abajo sin tocar el alto total —que tiene que
      # seguir siendo el de la toolbar que reemplaza—. La barra flotante no tiene ese límite
      # y conserva `sm`. Un `size:` explícito en la acción gana sobre ambos.
      #
      # `select_all_filtered:` y `filter_params:` van DESPUÉS del splat: son del componente,
      # no de quien declara la acción — la barra es la única que sabe si el modo "los N
      # filtrados" está disponible, y las acciones tienen que estar de acuerdo entre ellas.
      renders_many :actions, ->(**options) do
        Action::Component.new(
          size: toolbar? ? :xs : :sm,
          **options,
          select_all_filtered: select_all_filtered?,
          filter_params: filter_params
        )
      end
      renders_many :items, Item::Component

      VARIANTS = %i[floating toolbar].freeze

      # Alto de un control `sm` de daisyUI (btn-sm / input-sm), que es lo que le da su altura
      # a la toolbar del DataTable. La fila contextual la REEMPLAZA en el mismo hueco, así que
      # ambas declaran este mismo mínimo: si difieren, intercambiarlas empuja el listado.
      # `Bali::DataTable::Component::TOOLBAR_CLASSES` declara el gemelo, y un test lo fija.
      TOOLBAR_MIN_HEIGHT = "min-h-8"

      # Dos juegos de clases: la barra flotante (fuera de un listado) y la fila contextual
      # que ocupa el hueco de la toolbar de un DataTable mientras hay selección.
      CLASSES = {
        floating_bar: "fixed bottom-4 left-1/2 -translate-x-1/2 z-40 hidden",
        floating_bar_inner: "flex items-center shadow-xl rounded-lg overflow-hidden",
        counter: "bg-primary text-primary-content font-bold text-2xl px-4 py-2 rounded-l-lg",
        actions_wrapper: "flex gap-2 px-3 py-2 bg-base-100 rounded-r-lg",
        toolbar_bar: "hidden mb-4",
        # El tinte primario es el MISMO que marca las filas seleccionadas, y funciona sobre
        # cualquier fondo: `bg-base-200` era invisible en un shell cuyo fondo de página ya
        # es base-200 (verificado en el dummy), y la barra quedaba sin estado visible.
        #
        # ALTURA: esta fila REEMPLAZA a la toolbar del DataTable, así que tiene que medir
        # exactamente lo mismo o intercambiarlas empuja el listado (18px de salto medidos:
        # `py-2` aportaba 16 y el `border` 2). Por eso el contorno es un `ring` —box-shadow,
        # cero contribución al layout— en vez de un `border`, y no hay padding vertical:
        # el alto lo fija `min-h-8`, el mismo `TOOLBAR_MIN_HEIGHT` que declara la toolbar,
        # que es el alto de un control `sm` de daisyUI (btn-sm / input-sm). Si cambia uno,
        # cambia el otro.
        toolbar_bar_inner: "flex items-center gap-2 sm:gap-4 #{TOOLBAR_MIN_HEIGHT} rounded-box " \
                           "bg-primary/10 ring-1 ring-primary/20 px-3",
        toolbar_counter_wrapper: "flex items-center gap-1 text-sm shrink-0",
        toolbar_counter: "font-semibold",
        toolbar_actions_wrapper: "flex flex-wrap items-center gap-2 flex-1",
        # La oferta y el aviso viven DENTRO del contenedor de acciones, no sueltos en la
        # barra: en la variante flotante ese contenedor es el único que tiene fondo
        # (`bg-base-100`), y fuera de él el texto quedaba sobre el fondo de la página.
        select_all_offer: "hidden shrink-0",
        select_all_notice: "hidden shrink-0 text-sm italic opacity-70"
      }.freeze

      # @param variant [Symbol] :floating (barra fija abajo) o :toolbar (fila contextual)
      # @param standalone [Boolean] Emitir el `data-controller`. Dentro de un DataTable va
      #   en `false`: el controlador vive en el contenedor del DataTable. Dos controladores
      #   `bulk-actions` anidados se reparten los targets (Stimulus asigna cada target a su
      #   ancestro con controlador más cercano), así que la barra no vería las filas y el
      #   contador quedaría clavado en 0 — sin error, en silencio.
      # @param total_count [Integer, nil] Cuántos registros tiene el resultado filtrado
      #   COMPLETO, no la página. Con este dato la barra ofrece "Seleccionar los N
      #   resultados" cuando la selección ya cubre la página entera; sin él no hay oferta y
      #   la selección sigue siendo estrictamente la página visible. El DataTable lo saca de
      #   su `pagy`.
      # @param filter_params [Array<Array>, Hash] Los `q[...]` vigentes del listado, que cada
      #   acción re-emite como hidden fields para que el servidor pueda re-derivar el mismo
      #   scope (`MyFilterForm.new(scope, params).result`, el mismo código del index). Se
      #   aceptan pares `[name, value]` ya serializados o un hash anidado (`{ q: { ... } }`).
      #   El DataTable lo arma solo desde su `filter_form`.
      def initialize(variant: :floating, standalone: true, total_count: nil, filter_params: [],
                     **options)
        @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :floating
        @standalone = standalone
        @total_count = total_count&.to_i
        @filter_params = Bali::Filters::ActiveFilterParams.normalize(filter_params)
        @options = options
      end

      attr_reader :total_count, :filter_params

      # La oferta necesita un N que decir. Sin `total_count` no hay modo "todos los filtrados"
      # en ninguna parte: ni oferta, ni hidden `select_all_filtered`, ni re-emisión de
      # filtros — el POST de una barra que no lo pide sale byte por byte como salía antes.
      def select_all_filtered?
        @total_count.to_i.positive?
      end

      def toolbar?
        @variant == :toolbar
      end

      def standalone?
        @standalone
      end

      private

      def bar_classes
        CLASSES[toolbar? ? :toolbar_bar : :floating_bar]
      end

      def bar_inner_classes
        CLASSES[toolbar? ? :toolbar_bar_inner : :floating_bar_inner]
      end

      def actions_wrapper_classes
        CLASSES[toolbar? ? :toolbar_actions_wrapper : :actions_wrapper]
      end

      def component_classes
        class_names("bulk-actions-component", @options[:class])
      end

      def component_attributes
        data = @options[:data] || {}
        data = merge_data_attributes(data, controller: "bulk-actions") if standalone?

        @options.except(:class, :data).merge(class: component_classes, data: data)
      end

      def merge_data_attributes(existing, **new_attrs)
        (existing || {}).merge(new_attrs)
      end
    end
  end
end
