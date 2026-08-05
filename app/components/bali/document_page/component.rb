# frozen_string_literal: true

module Bali
  module DocumentPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_one :metadata
      renders_one :subheader

      # The three `references_*` keyword arguments this component used to forward
      # to BlockEditor now travel inside `config:`, the same value DocumentEditor
      # takes. Mirroring three of BlockEditor's twelve features was also why this
      # page could never render mentions: nobody noticed the other nine were
      # missing rather than deliberately excluded. See Bali::BlockEditor::Config.
      def initialize(
        initial_content: nil,
        toc_open: true,
        metadata_open: true,
        config: nil,
        **options
      )
        super(**options.slice(*PAGE_OPTIONS))
        @initial_content = initial_content
        @toc_open = toc_open
        @metadata_open = metadata_open
        @config = Bali::BlockEditor::Config.wrap(config)
        @options = options.except(*PAGE_OPTIONS)
      end

      # @deprecated El slot se llama `body` desde v3, igual que en los otros cuatro page
      #   components. Se elimina en 4.0. Renombra `with_preview` a `with_body`.
      def with_preview(...)
        Bali.deprecator.warn(
          "The `preview` slot of Bali::DocumentPage is deprecated. Rename `with_preview` to " \
          "`with_body`: the five page components now share one `body` slot."
        )
        with_body(...)
      end

      def block_editor?
        @initial_content.present?
      end

      def toc?
        block_editor?
      end

      def three_panel?
        toc? || metadata?
      end

      private

      attr_reader :initial_content, :config, :options

      def container_attributes
        options.except(:class).merge(
          class: page_container_class("document-page-component", options[:class]),
          data: controller_data
        )
      end

      def controller_data
        {
          controller: "document-page",
          document_page_toc_open_value: @toc_open,
          document_page_metadata_open_value: @metadata_open
        }
      end

      # DocumentPage es el único que pone algo a la izquierda de la barra de acciones: los
      # toggles de sus paneles. El resto de los cinco se queda con `render_actions_bar`.
      def page_header_actions
        helpers.tag.div(class: "flex items-center gap-2 flex-wrap") do
          helpers.safe_join([ render_toc_toggle, render_metadata_toggle, render_actions_group ].compact)
        end
      end

      def render_toc_toggle
        return unless toc?

        render_panel_toggle("panel-left", "toggleToc", "tocToggle", t(".toggle_toc"))
      end

      def render_metadata_toggle
        return unless three_panel? && metadata?

        render_panel_toggle("panel-right", "toggleMetadata", "metadataToggle", t(".toggle_details"))
      end

      def render_panel_toggle(icon, action, target, title)
        render(Bali::Button::Component.new(
          variant: :ghost, size: :sm, class: "btn-square", title: title,
          data: { action: "document-page##{action}", document_page_target: target }
        )) { render Bali::Icon::Component.new(icon, size: :small) }
      end

      # `secondary_actions?` además de `actions?`: una página que solo declara acciones
      # secundarias (el ⋯) no pintaba nada.
      def render_actions_group
        return unless actions? || secondary_actions?

        # Misma regla propia que la toolbar del DataTable, y por la misma razón: la clase
        # `divider-horizontal` de daisyUI trae un `width: 1rem` que ninguna utilidad puede
        # bajar, y ese ancho se sumaba al gap de la fila. El comentario largo con la
        # medición está en `data_table/component.html.erb` (#846).
        helpers.safe_join([
          helpers.tag.div(class: "w-0.5 h-6 bg-base-content/10"),
          render_actions_bar
        ])
      end

      # El cuerpo tiene tres orígenes: el editor de bloques cuando hay `initial_content`,
      # el slot `body`, o el contenido suelto del bloque.
      def page_body
        return render_block_editor if block_editor?

        body? ? super : content
      end

      def page_body?
        block_editor? || body? || content.present?
      end

      def render_block_editor
        render Bali::BlockEditor::Component.new(
          config: config,
          initial_content: initial_content,
          editable: false,
          table_of_contents: toc?,
          table_of_contents_container_id: toc? ? "document-page-toc-container" : nil,
          show_export_buttons: false
        )
      end
    end
  end
end
