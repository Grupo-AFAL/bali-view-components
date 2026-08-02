# frozen_string_literal: true

module Bali
  module DocumentEditor
    class Component < ApplicationViewComponent
      renders_one :toolbar

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
        param_key: :document,
        editable: true,
        auto_save: true,
        auto_save_delay: 30000,
        input_name: nil,
        config: nil,
        **options
      )
        @title = title
        @initial_content = initial_content
        @document_url = document_url
        @close_url = close_url || document_url
        @versions_url = versions_url
        @param_key = param_key.to_s
        # Kept derivable so an app whose routes already match does not have to
        # declare it, but it is now a value the host can name rather than one the
        # controller invents.
        @restore_version_url = restore_version_url || "#{document_url}/restore_version"
        @editable = editable
        @auto_save = auto_save
        @auto_save_delay = auto_save_delay
        @input_name = input_name || "#{@param_key}[content]"

        # The twelve editor keyword arguments this component used to re-declare and
        # forward untouched now travel as one value. See Bali::BlockEditor::Config.
        @config = Bali::BlockEditor::Config.wrap(config)
        @config = @config.merge(export_filename: title.parameterize) if @config.export_filename.blank?

        @options = options
        @instance_id = SecureRandom.hex(4)
      end

      def editable?
        @editable
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

      attr_reader :title, :initial_content, :document_url, :close_url,
                  :versions_url, :restore_version_url, :param_key,
                  :auto_save, :auto_save_delay, :input_name,
                  :config, :options, :instance_id

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
