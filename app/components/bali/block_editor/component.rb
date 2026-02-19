# frozen_string_literal: true

module Bali
  module BlockEditor
    class Component < ApplicationViewComponent
      attr_reader :input_name, :upload_url, :options

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        initial_content: nil,
        html_content: nil,
        input_name: nil,
        format: :json,
        editable: true,
        placeholder: nil,
        upload_url: :auto,
        theme: :light,
        export: false,
        export_filename: 'document',
        ai_url: nil,
        mentions_url: nil,
        mentions: nil,
        references_url: nil,
        references_resolve_url: nil,
        references_config: nil,
        multi_column: false,
        table_of_contents: false,
        comments: false,
        comments_url: nil,
        comments_user: nil,
        comments_users: nil,
        comments_users_url: nil,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @initial_content = initial_content
        @html_content = html_content
        @input_name = input_name
        @format = format
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
        @comments = comments
        @comments_url = comments_url
        @comments_user = comments_user
        @comments_users = comments_users
        @comments_users_url = comments_users_url

        @options = prepend_class_name(options, 'block-editor-component')
        @options = prepend_controller(@options, 'block-editor')
        @options = prepend_values(@options, 'block-editor', controller_values)
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

      def export_pdf?
        @export == true || Array(@export).map(&:to_sym).include?(:pdf)
      end

      def export_docx?
        @export == true || Array(@export).map(&:to_sym).include?(:docx)
      end

      def render?
        Bali.block_editor_enabled
      end

      private

      def controller_values
        base_values.merge(export_values)
      end

      def base_values
        {
          initial_content: serialized_content,
          html_content: @html_content || '',
          format: @format.to_s,
          editable: @editable,
          placeholder: @placeholder || '',
          upload_url: @upload_url,
          theme: @theme.to_s,
          export_filename: @export_filename,
          ai_url: @ai_url || '',
          mentions_url: @mentions_url || '',
          mentions: serialized_mentions,
          references_url: @references_url || '',
          references_resolve_url: @references_resolve_url || '',
          references_config: serialized_references_config,
          multi_column: @multi_column,
          table_of_contents: @table_of_contents,
          comments: @comments,
          comments_url: @comments_url || '',
          comments_user: serialized_comments_user,
          comments_users: serialized_comments_users,
          comments_users_url: @comments_users_url || ''
        }
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
          ''
        end
      end

      def serialized_references_config
        return '{}' if @references_config.blank?

        @references_config.transform_keys(&:to_s).to_json
      end

      def serialized_mentions
        return '[]' if @mentions.blank?

        Array(@mentions).map do |m|
          case m
          when String then { name: m }
          when Hash then m
          else m.respond_to?(:to_h) ? m.to_h : { name: m.to_s }
          end
        end.to_json
      end

      def serialized_comments_user
        return '{}' if @comments_user.blank?

        @comments_user.transform_keys(&:to_s).to_json
      end

      def serialized_comments_users
        return '[]' if @comments_users.blank?

        Array(@comments_users).map do |u|
          case u
          when Hash then u
          else u.respond_to?(:to_h) ? u.to_h : { id: u.to_s, username: u.to_s }
          end
        end.to_json
      end
    end
  end
end
