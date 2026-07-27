# frozen_string_literal: true

module Bali
  module BlockEditor
    # rubocop:disable Metrics/ClassLength
    class Component < ApplicationViewComponent
      attr_reader :input_name, :upload_url, :options

      # rubocop:disable Metrics/ParameterLists, Metrics/AbcSize
      def initialize(
        initial_content: nil,
        html_content: nil,
        markdown_content: nil,
        input_name: nil,
        format: :json,
        preset: :full,
        locale: nil,
        syntax_highlighting: true,
        editable: true,
        placeholder: nil,
        upload_url: :auto,
        theme: :light,
        export: false,
        export_filename: "document",
        ai_url: nil,
        mentions_url: nil,
        mentions: nil,
        references_url: nil,
        references_resolve_url: nil,
        references_config: nil,
        multi_column: false,
        table_of_contents: false,
        table_of_contents_container_id: nil,
        show_export_buttons: true,
        comments: false,
        comments_container_id: nil,
        **options
      )
        # rubocop:enable Metrics/ParameterLists, Metrics/AbcSize
        @initial_content = initial_content
        @html_content = html_content
        @markdown_content = markdown_content
        @input_name = input_name
        @format = format
        @preset = preset
        # Sigue a la app por default: un editor en inglés dentro de una UI en
        # español es el error más visible de una instalación sin configurar.
        @locale = locale || I18n.locale.to_s.split("-").first
        @syntax_highlighting = syntax_highlighting
        @editable = editable
        @placeholder = placeholder
        @upload_url_auto = (upload_url == :auto)
        @upload_url = upload_url == :auto ? nil : upload_url
        @theme = theme
        @export = export
        @export_filename = export_filename
        @ai_url = ai_url
        @mentions_url = mentions_url
        @mentions = mentions
        @references_url = references_url
        @references_resolve_url = references_resolve_url
        @references_config = references_config
        @multi_column = multi_column
        @table_of_contents = table_of_contents
        @table_of_contents_container_id = table_of_contents_container_id
        @show_export_buttons = show_export_buttons
        @comments_container_id = comments_container_id

        comments_config = comments.is_a?(Hash) ? comments.transform_keys(&:to_sym) : nil
        @comments       = comments_config.present?
        @comments_url   = comments_config&.fetch(:url, nil)
        @comments_user  = comments_config&.fetch(:user, nil)
        @comments_users = comments_config&.fetch(:users, nil)
        @comments_users_url = comments_config&.fetch(:users_url, nil)

        @options = prepend_class_name(options, "block-editor-component")
        @options = prepend_controller(@options, "block-editor")
        @options = prepend_values(@options, "block-editor", controller_values)
      end

      # Resolve upload_url at render time (not in initialize) because
      # engine route helpers require the view context which is only available here.
      def before_render
        return unless @upload_url_auto && editable?

        resolved = Bali.block_editor_upload_url || resolve_engine_upload_path
        return unless resolved

        @upload_url = resolved
        @options[:data] ||= {}
        @options[:data][:'block-editor-upload-url-value'] = resolved
      end

      def editable?
        @editable
      end

      def export_enabled?
        @export.present? && @export != false
      end

      def show_export_buttons?
        export_enabled? && @show_export_buttons
      end

      def export_pdf?
        @export == true || Array(@export).map(&:to_sym).include?(:pdf)
      end

      def export_docx?
        @export == true || Array(@export).map(&:to_sym).include?(:docx)
      end

      def render?
        return true if Bali.block_editor_enabled

        warn_disabled
        # In development, render a visible placeholder instead of nothing so the
        # mistake is impossible to miss. Test keeps the "renders nothing"
        # contract, and production never shows scaffolding to users.
        Rails.env.development?
      end

      def disabled?
        !Bali.block_editor_enabled
      end

      # What the hidden input carries before the editor has mounted and synced.
      # It must round-trip the ORIGINAL content: if the user submits without
      # touching the editor, an empty value here would silently blank the field.
      def hidden_input_value
        case @format.to_sym
        when :markdown then @markdown_content.to_s
        when :html then @html_content.to_s
        else serialized_content
        end
      end

      private

      # A disabled component renders an empty string: no markup, no controller,
      # no error — and `assert_response :success` still passes. That silence is
      # the single most common way this component is mis-installed, so say so
      # loudly where it is safe to: logs always, plus a visible placeholder in
      # development and test (see component.html.erb).
      def warn_disabled
        Rails.logger.warn(
          "[Bali] BlockEditor::Component was rendered but `Bali.block_editor_enabled` is false, " \
          "so nothing was output. Set `config.block_editor_enabled = true` in " \
          "config/initializers/bali.rb and install the npm packages listed in " \
          "docs/api/block-editor.md."
        )
      end

      def controller_values
        base_values.merge(export_values)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def base_values
        {
          initial_content: serialized_content,
          html_content: @html_content || "",
          markdown_content: @markdown_content || "",
          format: @format.to_s,
          preset: @preset.to_s,
          locale: @locale.to_s,
          syntax_highlighting: @syntax_highlighting,
          editable: @editable,
          placeholder: @placeholder || "",
          upload_url: @upload_url,
          theme: @theme.to_s,
          export_filename: @export_filename,
          ai_url: @ai_url || "",
          mentions_url: @mentions_url || "",
          mentions: serialized_mentions,
          references_url: @references_url || "",
          references_resolve_url: @references_resolve_url || "",
          references_config: serialized_references_config,
          multi_column: @multi_column,
          table_of_contents: @table_of_contents,
          table_of_contents_container_id: @table_of_contents_container_id || "",
          comments: @comments,
          comments_container_id: @comments_container_id || "",
          comments_url: @comments_url || "",
          comments_user: serialized_comments_user,
          comments_users: serialized_comments_users,
          comments_users_url: @comments_users_url || ""
        }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def export_values
        {
          export_pdf: export_enabled? && export_pdf?,
          export_docx: export_enabled? && export_docx?
        }
      end

      def resolve_engine_upload_path
        helpers.bali.block_editor_uploads_path
      rescue NoMethodError
        nil
      end

      def serialized_content
        case @initial_content
        when Hash, Array
          @initial_content.to_json
        when String
          @initial_content
        else
          ""
        end
      end

      def serialized_references_config
        return "{}" if @references_config.blank?

        @references_config.transform_keys(&:to_s).to_json
      end

      def serialized_mentions
        return "[]" if @mentions.blank?

        Array(@mentions).map do |m|
          case m
          when String then { name: m }
          when Hash then m
          else m.respond_to?(:to_h) ? m.to_h : { name: m.to_s }
          end
        end.to_json
      end

      def serialized_comments_user
        return "{}" if @comments_user.blank?

        @comments_user.transform_keys(&:to_s).to_json
      end

      def serialized_comments_users
        return "[]" if @comments_users.blank?

        Array(@comments_users).map do |u|
          case u
          when Hash then u
          else u.respond_to?(:to_h) ? u.to_h : { id: u.to_s, username: u.to_s }
          end
        end.to_json
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
