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

        # This page's three `references_*` keywords also moved into `config:` in v3, and
        # left loose they were painted as attributes of the div: the reference chips of the
        # published record came out with the default icon and label, without re-resolving
        # the name, and nothing said so (#1092).
        Bali::BlockEditor::Config.warn_stray_keywords(@options, component: self.class.name)
        reject_format_keyword
      end

      # @deprecated The slot is called `body` since v3, the same as in the other four page
      #   components. It is removed in 4.0. Rename `with_preview` to `with_body`.
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

      # `format:` pins the way the editor WRITES content, and this page never writes: it
      # mounts its BlockEditor with `editable: false` and no `input_name`, so it renders no
      # hidden input and there is nothing to serialize. Accepting it and forwarding it
      # would be dead API — a keyword you can pass that does nothing — and letting it fall
      # into `**options` paints it as `format="blocks"` on the div, silently, which is the
      # trap of #1092. So it says so out loud and names the component that does take it.
      #
      # It raises rather than warns because there is nothing to deprecate: it never meant
      # anything here.
      def reject_format_keyword
        return unless @options.key?(:format)

        raise ArgumentError,
              "#{self.class.name}: `format:` pins how the editor WRITES content, and this " \
              "page never writes — it mounts a read-only editor with no input. Pass it to " \
              "Bali::DocumentEditor or Bali::BlockEditor, which persist."
      end

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

      # DocumentPage is the only one that puts anything to the left of the actions bar: its
      # panel toggles. The other four of the five stay with `render_actions_bar`.
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

      # `secondary_actions?` as well as `actions?`: a page that only declares secondary
      # actions (the ⋯) painted nothing.
      def render_actions_group
        return unless actions? || secondary_actions?

        # The same hand-rolled rule as the DataTable toolbar, and for the same reason:
        # daisyUI's `divider-horizontal` class carries a `width: 1rem` that no utility can
        # bring down, and that width added itself to the row's gap. The long comment with
        # the measurement is in `data_table/component.html.erb` (#846).
        helpers.safe_join([
          helpers.tag.div(class: "w-0.5 h-6 bg-base-content/10"),
          render_actions_bar
        ])
      end

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
