# frozen_string_literal: true

module Bali
  module BlockEditor
    # rubocop:disable Metrics/ClassLength
    class Component < ApplicationViewComponent
      attr_reader :input_name, :upload_url, :options

      # Distinguishes "the caller did not pass this" from "the caller passed the
      # value that happens to be the default". Without it, `config:` could not be
      # overridden by an explicit `comments: false` or `upload_url: nil`, because
      # both are indistinguishable from an untouched default.
      UNSET = Object.new.freeze
      private_constant :UNSET

      # rubocop:disable Metrics/ParameterLists, Metrics/AbcSize
      def initialize(
        initial_content: nil,
        html_content: nil,
        markdown_content: nil,
        input_name: nil,
        format: :json,
        preset: :full,
        locale: nil,
        syntax_highlighting: UNSET,
        editable: true,
        placeholder: nil,
        upload_url: UNSET,
        theme: :light,
        export: UNSET,
        export_filename: UNSET,
        ai_url: UNSET,
        mentions_url: UNSET,
        mentions: UNSET,
        references_url: UNSET,
        references_resolve_url: UNSET,
        references_config: UNSET,
        multi_column: UNSET,
        table_of_contents: false,
        table_of_contents_container_id: nil,
        show_export_buttons: true,
        comments: UNSET,
        comments_container_id: nil,
        config: nil,
        **options
      )
        # rubocop:enable Metrics/ParameterLists, Metrics/AbcSize
        # A shared Config supplies the feature set; an explicit keyword overrides
        # one item of it. That order is the useful one: a host passes the bundle
        # its app always uses and then turns a single feature off for one editor.
        @config = Config.wrap(config).merge(
          {
            syntax_highlighting: syntax_highlighting, upload_url: upload_url,
            export: export, export_filename: export_filename, ai_url: ai_url,
            mentions_url: mentions_url, mentions: mentions,
            references_url: references_url, references_resolve_url: references_resolve_url,
            references_config: references_config, multi_column: multi_column,
            comments: comments
          }.reject { |_, value| UNSET.equal?(value) }
        )

        @initial_content = initial_content
        @html_content = html_content
        @markdown_content = markdown_content
        @input_name = input_name
        @format = format
        @preset = preset
        # Sigue a la app por default: un editor en inglés dentro de una UI en
        # español es el error más visible de una instalación sin configurar.
        @locale = locale || I18n.locale.to_s.split("-").first
        @syntax_highlighting = @config.syntax_highlighting
        @syntax_highlighting = Bali.block_editor_syntax_highlighting if @syntax_highlighting.nil?
        @editable = editable
        @placeholder = placeholder
        @upload_url_auto = (@config.upload_url == :auto)
        @upload_url = @config.upload_url == :auto ? nil : @config.upload_url
        @theme = theme
        @export = @config.export
        @export_filename = @config.export_filename || "document"
        @ai_url = @config.ai_url
        @mentions_url = @config.mentions_url
        @mentions = @config.mentions
        @references_url = @config.references_url
        @references_resolve_url = @config.references_resolve_url
        @references_config = @config.references_config
        @multi_column = @config.multi_column
        @table_of_contents = table_of_contents
        @table_of_contents_container_id = table_of_contents_container_id
        @show_export_buttons = show_export_buttons
        @comments_container_id = comments_container_id

        comments_config = @config.comments.is_a?(Hash) ? @config.comments.transform_keys(&:to_sym) : nil
        @comments       = comments_config.present?
        @comments_url   = comments_config&.fetch(:url, nil)
        @comments_user  = comments_config&.fetch(:user, nil)
        @comments_users = comments_config&.fetch(:users, nil)
        @comments_users_url = comments_config&.fetch(:users_url, nil)
        # -1 stands for "not configured": 0 is a real value that turns polling off,
        # so it cannot double as the unset marker.
        @comments_poll_interval = comments_config&.fetch(:poll_interval, nil) || -1

        @options = prepend_class_name(options, "block-editor-component")
        @options = prepend_controller(@options, "block-editor")
        @options = prepend_values(@options, "block-editor", controller_values)
      end

      # Two things can only be resolved here, both for the same reason: the view
      # context does not exist yet in `initialize`. Engine route helpers need it,
      # and so does `translate` -- ViewComponent raises
      # TranslateCalledBeforeRenderError if the strings are gathered any earlier.
      def before_render
        @options = prepend_values(@options, "block-editor", { translations: translations_json })

        resolve_auto_upload_url
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
          comments_users_url: @comments_users_url || "",
          comments_poll_interval: @comments_poll_interval
        }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # Every string the React bundle writes into the DOM, in one JSON value --
      # the channel `filters/condition/component.rb#translations_json` already
      # uses. They were hardcoded in English across four modules, so a Spanish
      # app still got "File is too large (12.4 MB)..." inside its own editor.
      #
      # The three that carry runtime data keep their Rails placeholder and are
      # substituted in JavaScript: only the browser knows the file size, the HTTP
      # status or the unresolved user id.
      def translations_json
        {
          load_failed: t("bali_view.block_editor.load_failed"),
          table_of_contents: t("bali_view.block_editor.table_of_contents"),
          upload_not_configured: t("bali_view.block_editor.upload_not_configured"),
          upload_too_large: t("bali_view.block_editor.upload_too_large"),
          upload_failed: t("bali_view.block_editor.upload_failed"),
          user_fallback: t("bali_view.block_editor.user_fallback"),
          plain_text: t("bali_view.block_editor.plain_text")
        }.to_json
      end

      def resolve_auto_upload_url
        return unless @upload_url_auto && editable?

        resolved = Bali.block_editor_upload_url || resolve_engine_upload_path
        return unless resolved

        @upload_url = resolved
        @options[:data] ||= {}
        @options[:data][:'block-editor-upload-url-value'] = resolved
      end

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
