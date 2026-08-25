# frozen_string_literal: true

module Bali
  module BlockEditor
    # rubocop:disable Metrics/ClassLength
    class Component < ApplicationViewComponent
      attr_reader :input_name, :upload_url, :options

      # The size of the text the editor renders, as one class on the wrapper.
      # BlockNote sizes the editor body once and derives everything inside it --
      # headings, lists, quotes, table cells -- in `em` off that value, so a
      # single font-size scales the whole document in proportion. `index.css`
      # holds the actual measurements.
      SIZES = {
        xs: "block-editor-size-xs",
        sm: "block-editor-size-sm",
        md: "block-editor-size-md",
        lg: "block-editor-size-lg"
      }.freeze

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
        size: :md,
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
        readonly: nil,
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
        @editable = resolve_editable(editable, readonly)
        @placeholder = placeholder
        @upload_url_auto = (@config.upload_url == :auto)
        @upload_url = @upload_url_auto ? nil : @config.upload_url

        # Un visor no sube archivos, y no pasar `upload_url:` no APAGA las subidas: las
        # ENCIENDE, porque su default es `:auto` y eso resuelve al endpoint del engine.
        # `:auto` ya lo contemplaba —`resolve_auto_upload_url` mira `editable?`—, pero una
        # url explícita no, así que una pantalla de solo lectura seguía aceptando subidas:
        # blobs `unattached` que la purga de huérfanos del host se lleva a los siete días
        # (#1092). La regla queda entera: sin edición no hay subida, venga de donde venga.
        unless @editable
          @upload_url_auto = false
          @upload_url = nil
        end
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
        # `url: :auto` (#706) points the editor at the engine's own endpoints for one
        # host record. It needs the view context to build the path, so all initialize
        # does is remember the intent and check the record is usable -- raising here
        # rather than in before_render puts the error on the call site.
        @comments_url_auto = (@comments_url == :auto)
        @comments_url = nil if @comments_url_auto
        @comments_commentable = comments_config&.fetch(:commentable, nil)
        validate_comments_commentable! if @comments_url_auto
        @comments_user  = comments_config&.fetch(:user, nil)
        @comments_users = comments_config&.fetch(:users, nil)
        @comments_users_url = comments_config&.fetch(:users_url, nil)
        @comments_threads = comments_config&.fetch(:threads, nil)
        # -1 stands for "not configured": 0 is a real value that turns polling off,
        # so it cannot double as the unset marker.
        @comments_poll_interval = comments_config&.fetch(:poll_interval, nil) || -1

        Config.warn_stray_keywords(options, component: self.class.name)

        @options = prepend_class_name(options, "block-editor-component")
        @options = prepend_class_name(@options, size_class(size))
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
        resolve_auto_comments_url
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

      # @deprecated `readonly:` es el nombre de Rails y la primera conjetura de cualquiera,
      #   y hasta v3.1 era una trampa muda: no es parámetro del componente, así que caía en
      #   `**options` y salía como `readonly="readonly"` en un `<div>`, donde no significa
      #   nada. Dos pantallas "de solo lectura" de una app anfitriona eran editables, y
      #   además aceptaban subidas, porque `upload_url:` por omisión es `:auto` (#1092).
      #   Se elimina en 4.0.
      def resolve_editable(editable, readonly)
        return editable if readonly.nil?

        Bali.deprecator.warn(
          "Bali::BlockEditor(readonly:) is deprecated and is removed in 4.0. " \
          "Write `editable: #{!readonly}`."
        )

        !readonly
      end

      # A disabled component renders an empty string: no markup, no controller,
      # no error — and `assert_response :success` still passes. That silence is
      # the single most common way this component is mis-installed, so say so
      # loudly where it is safe to: logs always, plus a visible placeholder in
      # development and test (see component.html.erb).
      # nil renders the default; anything unknown raises instead of defaulting in
      # silence -- the same contract Bali::Alert and Bali::Tag use.
      # `size.to_sym` would turn an Integer — the value that means the HTML
      # attribute on the input families, and now reachable through
      # `block_editor_group` (#1076) — into a NoMethodError; letting it miss
      # the fetch instead keeps the rejection one clear message.
      def size_class(size)
        return SIZES[:md] if size.nil?

        key = size.respond_to?(:to_sym) ? size.to_sym : size
        SIZES.fetch(key) do
          raise ArgumentError,
                "#{self.class.name}: unknown size #{size.inspect}. " \
                "Valid: #{SIZES.keys.map(&:inspect).join(', ')}."
        end
      end

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
          comments_threads: serialized_comments_threads,
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
        # Same string key `prepend_values` uses -- see resolve_auto_comments_url. This
        # one happened to work with a symbol only because `prepend_values` skips nil
        # values, so there was nothing to collide with.
        @options[:data] ||= {}
        @options[:data]["block-editor-upload-url-value"] = resolved
      end

      # The commentable is the whole point of `:auto`: the engine scopes every one of
      # the nine endpoints to it, and `RESTThreadStore._buildUrl` carries the query
      # string from this base URL to all of them.
      def resolve_auto_comments_url
        return unless @comments_url_auto

        resolved = resolve_engine_threads_path
        return unless resolved

        @comments_url = resolved
        # The STRING key is the one `prepend_values` already wrote in initialize (with
        # `""`, since the URL was not known yet). A symbol key here would add a second
        # data attribute instead of replacing that one, and the empty one -- being
        # first -- is the one the browser reads.
        @options[:data] ||= {}
        @options[:data]["block-editor-comments-url-value"] = resolved
      end

      def validate_comments_commentable!
        return if @comments_commentable.respond_to?(:id) &&
                  @comments_commentable.class.respond_to?(:polymorphic_name)

        raise ArgumentError,
              "comments: { url: :auto } requires `commentable:` to be an Active Record " \
              "record (got #{@comments_commentable.inspect}). The engine scopes threads " \
              "to it; there is no unscoped thread list."
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

      # nil when the host did not mount the engine, same as uploads: the editor falls
      # back to the in-memory store instead of pointing at a URL that answers 404.
      def resolve_engine_threads_path
        helpers.bali.block_editor_threads_path(
          commentable_type: @comments_commentable.class.polymorphic_name,
          commentable_id: @comments_commentable.id
        )
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

      # Sin `references_config:` explícito manda el registry (#708): declarar un tipo en
      # `Bali.entity_reference_types` con su `display:` basta para que su chip salga con su
      # icono, su etiqueta y su color, sin repetir la declaración en cada editor. Un hash
      # explícito sigue ganando — un editor puede pintar un tipo distinto al del registry.
      def serialized_references_config
        config = @references_config.presence || Bali.entity_references_config
        return "{}" if config.blank?

        config.transform_keys(&:to_s).to_json
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

      # Threads the in-memory store opens with. Only for a store that does not persist:
      # with `url:` the REST store fetches the list and owns it, so a seed there would be
      # gone on the first poll (see useComments).
      #
      # A seeded thread lists and reads, but anchors to nothing in the text. That is not a
      # gap in this method — BlockNote's `comment` mark declares `blocknoteIgnore`, so it
      # is deliberately absent from the block JSON and there is no way to express one in
      # `initial_content`. The comments sidebar reads the STORE, which is why a thread
      # still shows.
      def serialized_comments_threads
        return "[]" if @comments_threads.blank?

        Array(@comments_threads).map { |thread| thread.respond_to?(:to_h) ? thread.to_h : thread }.to_json
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
