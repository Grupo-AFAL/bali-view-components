# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Form helpers for the BlockNote-based Block Editor.
    #
    # The goal is parity with Rails' own `rich_text_area`: bind a plain text
    # column and get an editor, with no wiring at the call site.
    #
    #   f.rich_text_group :description             # bold/italic/lists, stored as Markdown
    #   f.rich_text_group :body, preset: :full     # full block editor
    #
    # Storing Markdown (the default) is what keeps the rest of an application
    # working: search, plain-text exports, APIs and LLM prompts keep reading the
    # column the way they always did. Pass `format: :json` for BlockNote's native
    # document JSON when the content never leaves the editor.
    #
    # NOTE: not to be confused with `rich_text_area_group`, which is the
    # ActionText/Trix helper and has nothing to do with this component.
    module RichTextFields
      DEFAULT_RICH_TEXT_FORMAT = :markdown

      def rich_text_group(method, options = {})
        block_editor_group(method, { preset: :simple }.merge(options))
      end

      def rich_text(method, options = {})
        block_editor(method, { preset: :simple }.merge(options))
      end

      def block_editor_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          block_editor(method, options)
        end
      end

      # Options consumed by the surrounding field group / field_helper. They must
      # not reach the component, which forwards anything it does not recognise
      # straight onto the wrapper div as an HTML attribute — `label="..."` and
      # `help="..."` would end up in the markup.
      #
      # `required` is the one addition to the canonical list: it is a real
      # attribute on an <input>, so `html_attributes` keeps it, but the block
      # editor has no input of its own to put it on.
      FIELD_GROUP_OPTIONS = (HtmlUtils::WRAPPER_OPTIONS + %i[required]).freeze

      def block_editor(method, options = {})
        opts = options.except(*FIELD_GROUP_OPTIONS, :format, :input_name)
        format = (options[:format] || DEFAULT_RICH_TEXT_FORMAT).to_sym

        component_options = opts.merge(
          input_name: options[:input_name] || field_name(method),
          format: format,
          **content_for_format(method, format)
        )

        field_helper(
          method,
          @template.render(Bali::BlockEditor::Component.new(**component_options)),
          options
        )
      end

      private

      # The stored column value is handed to the editor through the prop that
      # matches the storage format, so the editor parses it instead of showing
      # the raw source.
      def content_for_format(method, format)
        value = object.respond_to?(method) ? object.public_send(method) : nil

        case format
        when :markdown then { markdown_content: value.to_s }
        when :html then { html_content: value.to_s }
        else { initial_content: value }
        end
      end
    end
  end
end
