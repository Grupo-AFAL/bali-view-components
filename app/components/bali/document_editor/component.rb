# frozen_string_literal: true

module Bali
  module DocumentEditor
    class Component < ApplicationViewComponent
      renders_one :toolbar

      # Tells "the host did not pass `format:`" apart from "it passed the value that
      # happens to be the default", which is what makes the opinionated default below
      # possible without taking away the host's ability to ask for `:json` on purpose.
      # Same sentinel as BlockEditor::Component.
      UNSET = Object.new.freeze
      private_constant :UNSET

      # Every URL the controller talks to is declared here. It used to build two of
      # them by string interpolation -- `"#{document_url}/restore_version"` and
      # `"#{versions_url}/#{id}"` -- which made the host's routing file a guess the
      # JavaScript was making. `restore_version_url:` and the `url` each version
      # carries in its own JSON replace that; see docs/guides/migration-v2-to-v3.md.
      def initialize(
        title:,
        initial_content:,
        document_url:,
        close_url: nil,
        versions_url: nil,
        restore_version_url: nil,
        record: nil,
        param_key: :document,
        editable: true,
        auto_save: true,
        auto_save_delay: 30000,
        input_name: nil,
        config: nil,
        format: UNSET,
        readonly: nil,
        **options
      )
        @title = title
        @initial_content = initial_content
        @document_url = document_url
        @close_url = close_url || document_url
        @param_key = param_key.to_s

        # `:auto` means "the mounted engine's own endpoints" (#707) and needs the record
        # to name in the query string, since those routes are not nested. Same shape as
        # BlockEditor's `upload_url: :auto`; resolved in `before_render`, where the view
        # context that owns the route helpers finally exists.
        @record = record
        @versions_url_auto = (versions_url == :auto)
        @versions_url = @versions_url_auto ? nil : versions_url
        @restore_version_url_auto = (restore_version_url == :auto)
        # Kept derivable so an app whose routes already match does not have to
        # declare it, but it is now a value the host can name rather than one the
        # controller invents.
        @restore_version_url =
          if @restore_version_url_auto
            nil
          else
            restore_version_url || "#{document_url}/restore_version"
          end
        @editable = resolve_editable(editable, readonly)
        @auto_save = auto_save
        @auto_save_delay = auto_save_delay
        @input_name = input_name || "#{@param_key}[content]"

        # The twelve editor keyword arguments this component used to re-declare and
        # forward untouched now travel as one value. See Bali::BlockEditor::Config.
        @config = Bali::BlockEditor::Config.wrap(config)
        @config = @config.merge(export_filename: title.parameterize) if @config.export_filename.blank?
        @editor_format = resolve_format(format)

        Bali::BlockEditor::Config.warn_stray_keywords(options, component: self.class.name)

        @options = options
        @instance_id = SecureRandom.hex(4)
      end

      # Engine route helpers need a view context, which does not exist in `initialize`.
      # Same reason `BlockEditor::Component#before_render` resolves its upload URL there.
      def before_render
        resolve_auto_version_urls
      end

      def editable?
        @editable
      end

      # The threads sidebar is portaled into the panel below, so it sits outside
      # `.block-editor-component` and the flag that component carries never reaches
      # it. The panel gets its own copy. See `BlockEditor::Config#comments_sidebar`.
      def comments_sidebar_read_only?
        @config.comments_sidebar_read_only?
      end

      def comments?
        @config.comments.present?
      end

      def versions?
        @versions_url.present?
      end

      def export?
        @config.export.present? && @config.export != false
      end

      private

      # The form the content is persisted in, when the host does not name it (#1098).
      #
      # `format:` deliberately does not travel in `config:` —"each wrapper decides"— and
      # this wrapper was not deciding: it neither accepted nor forwarded it, so the screen
      # that needs it MOST (a document editor with comments and auto-save) was left with
      # the adaptive `:json` that #1091 exists to end. Now it accepts it, and when it is
      # not passed one it really does decide.
      #
      # With `comments:` on that is `:prosemirror`, which is the only combination that
      # loses nothing: `:json` switches BY ITSELF to that very form as soon as somebody
      # leaves a comment —the first reader triggers it, not the host— and with auto-save
      # that schema rewrite reaches the column without anyone asking for it. Pinning it
      # means writing from the first save what the adaptive one was going to write anyway,
      # but declared. (`:blocks` is no good as a default: it loses each thread's anchor.)
      #
      # An explicit `format:` always wins, `:json` included: a host that wants the adaptive
      # one asks for it and gets it.
      def resolve_format(format)
        return format unless format == UNSET

        @config.comments.present? ? :prosemirror : :json
      end

      # @deprecated See Bali::BlockEditor::Component#resolve_editable. Removed in 4.0.
      def resolve_editable(editable, readonly)
        return editable if readonly.nil?

        Bali.deprecator.warn(
          "Bali::DocumentEditor(readonly:) is deprecated and is removed in 4.0. " \
          "Write `editable: #{!readonly}`."
        )

        !readonly
      end

      attr_reader :title, :initial_content, :document_url, :close_url,
                  :versions_url, :restore_version_url, :param_key,
                  :auto_save, :auto_save_delay, :input_name,
                  :config, :editor_format, :options, :instance_id

      # Without a record there is nothing to name in the query string, so `:auto` resolves
      # to nothing and the history panel simply does not render: an off switch beats a
      # panel whose every request 404s. The engine also has to be mounted -- if it is not,
      # the route helper raises and the same silence applies.
      def resolve_auto_version_urls
        return unless @versions_url_auto || @restore_version_url_auto
        return if @record.nil?

        record_params = {
          record_type: @record.class.polymorphic_name,
          record_id: @record.id
        }

        @versions_url = engine_path(:content_versions_path, record_params) if @versions_url_auto
        return unless @restore_version_url_auto

        @restore_version_url = engine_path(:restore_content_versions_path, record_params) ||
                               "#{document_url}/restore_version"
      end

      def engine_path(helper, params)
        helpers.bali.public_send(helper, params)
      rescue NoMethodError
        nil
      end

      def toc_container_id
        "document-editor-toc-#{instance_id}"
      end

      def comments_container_id
        "document-editor-comments-#{instance_id}"
      end

      def container_attributes
        options.except(:class).merge(
          class: class_names("document-editor-overlay fixed inset-0 z-[var(--bali-z-modal)] flex flex-col bg-base-100", options[:class]),
          data: controller_data
        )
      end

      def controller_data
        {
          controller: "document-editor",
          document_editor_auto_save_value: auto_save,
          document_editor_auto_save_delay_value: auto_save_delay,
          document_editor_document_url_value: document_url,
          document_editor_close_url_value: close_url,
          document_editor_versions_url_value: versions_url || "",
          document_editor_restore_version_url_value: restore_version_url,
          document_editor_param_key_value: param_key,
          document_editor_input_name_value: input_name,
          document_editor_toc_open_value: true,
          document_editor_panel_value: ""
        }.merge(translation_data)
      end

      # The controller writes the save status and the preview label into the DOM
      # after a fetch resolves, so neither can be rendered as text: they have to
      # reach the JavaScript as values. `%{time}` and `%{number}` stay
      # uninterpolated on purpose -- only the browser knows them -- and the
      # controller substitutes them, the way `kanban/index.js` already does.
      #
      # The locale goes with them so `Intl.RelativeTimeFormat` can format the age
      # of each version; it used to be four hardcoded English strings.
      # `timeago/component.rb` emits it the same way.
      def translation_data
        {
          document_editor_locale_value: I18n.locale,
          document_editor_status_unsaved_value: t("bali_view.document_editor.status_unsaved"),
          document_editor_status_saving_value: t("bali_view.document_editor.status_saving"),
          document_editor_status_saved_value: t("bali_view.document_editor.status_saved"),
          document_editor_status_failed_value: t("bali_view.document_editor.status_failed"),
          document_editor_version_label_value: t("bali_view.document_editor.version_label"),
          document_editor_restore_confirm_value: t("bali_view.document_editor.restore_confirm")
        }
      end
    end
  end
end
