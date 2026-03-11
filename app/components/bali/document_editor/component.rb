# frozen_string_literal: true

module Bali
  module DocumentEditor
    class Component < ApplicationViewComponent
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        title:,
        initial_content:,
        document_url:,
        close_url: nil,
        versions_url: nil,
        editable: true,
        auto_save: true,
        auto_save_delay: 30000,
        comments: nil,
        export: false,
        export_filename: nil,
        input_name: "document[content]",
        ai_url: nil,
        mentions_url: nil,
        mentions: nil,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @title = title
        @initial_content = initial_content
        @document_url = document_url
        @close_url = close_url || document_url
        @versions_url = versions_url
        @editable = editable
        @auto_save = auto_save
        @auto_save_delay = auto_save_delay
        @comments_config = comments
        @export = export
        @export_filename = export_filename || title.parameterize
        @input_name = input_name
        @ai_url = ai_url
        @mentions_url = mentions_url
        @mentions = mentions
        @options = options
        @instance_id = SecureRandom.hex(4)
      end

      def editable?
        @editable
      end

      def comments?
        @comments_config.present?
      end

      def versions?
        @versions_url.present?
      end

      private

      attr_reader :title, :initial_content, :document_url, :close_url,
                  :versions_url, :auto_save, :auto_save_delay,
                  :export, :export_filename, :input_name,
                  :ai_url, :mentions_url, :mentions, :options,
                  :instance_id

      def toc_container_id
        "document-editor-toc-#{instance_id}"
      end

      def comments_container_id
        "document-editor-comments-#{instance_id}"
      end

      def container_attributes
        options.except(:class).merge(
          class: class_names("document-editor-overlay fixed inset-0 z-50 flex flex-col bg-base-100", options[:class]),
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
          document_editor_input_name_value: input_name,
          document_editor_toc_open_value: true,
          document_editor_panel_value: ""
        }
      end
    end
  end
end
