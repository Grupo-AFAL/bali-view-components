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

      def rich_text_group(method, **options)
        block_editor_group(method, **{ preset: :simple }.merge(options))
      end

      def rich_text_field(method, **options)
        block_editor_field(method, **{ preset: :simple }.merge(options))
      end

      # The caption stays a `<legend>`: what the user types into is a ProseMirror
      # `contenteditable` BlockNote creates client-side, so at render time there
      # is no id for a `for` to point at. Naming it needs an `aria-labelledby`
      # written by the editor once it mounts — the one control this issue leaves
      # unnamed, tracked apart.
      def block_editor_group(method, **options)
        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false)
        ) do
          block_editor_field(method, **options)
        end
      end

      # Options consumed by the surrounding field group / field_helper. They must
      # not reach the component, which forwards anything it does not recognise
      # straight onto the wrapper div as an HTML attribute — `label="..."` and
      # `help="..."` would end up in the markup.
      #
      # `CONTROL_ONLY_OPTIONS` rides along for the same reason — minus `:size`.
      # On the input families that option can only be the HTML attribute, but on
      # this component it is API: the text scale. Stripping it here made the
      # option unreachable from the helper, silently — every editor rendered
      # `md` no matter what the call site said (#1076). `:required` stays: the
      # editor is a widget over a hidden field, which constraint validation
      # never reads (see required_option_test.rb).
      FIELD_GROUP_OPTIONS = (
        HtmlUtils::WRAPPER_OPTIONS + HtmlUtils::CONTROL_ONLY_OPTIONS - [ :size ]
      ).freeze

      def block_editor_field(method, **options)
        # This family never reaches `html_attributes`, so it needs its own call to
        # the guard: the component forwards anything it does not recognise onto its
        # wrapper div, which is where `hint="…"` was landing (#1111).
        warn_mistaken_options(options)
        # `input_id:` is stripped and not honoured: the hidden input's id is the
        # component's own, derived alongside the editor's container id, and a
        # `<legend>` caption (`control_id: false`) points at nothing to keep honest.
        opts = options.except(*FIELD_GROUP_OPTIONS, :format,
                              *HtmlUtils::NON_MODEL_OPTIONS,
                              *HtmlUtils::MISTAKEN_OPTIONS.keys)
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
