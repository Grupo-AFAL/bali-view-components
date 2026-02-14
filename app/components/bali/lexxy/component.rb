# frozen_string_literal: true

module Bali
  module Lexxy
    class Component < ApplicationViewComponent
      renders_many :prompts, ->(trigger:, name:, **options) do
        Prompt::Component.new(trigger: trigger, name: name, **options)
      end

      # rubocop:disable Metrics/ParameterLists
      def initialize(name: nil, value: nil, placeholder: nil, toolbar: true,
                     attachments: true, markdown: false, multi_line: true,
                     rich_text: true, required: false, disabled: false,
                     autofocus: false, preset: nil, **options)
        @name = name
        @value = value
        @placeholder = placeholder
        @toolbar = toolbar
        @attachments = attachments
        @markdown = markdown
        @multi_line = multi_line
        @rich_text = rich_text
        @required = required
        @disabled = disabled
        @autofocus = autofocus
        @preset = preset
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def wrapper_classes
        class_names('lexxy-component', @options[:class])
      end

      # Lexxy uses camelCase HTML attributes (multiLine, richText).
      # Rails' tag helper dasherizes keys, so we render attributes manually.
      def editor_attributes_tag
        editor_attributes.map do |k, v|
          case v
          when true then k.to_s
          when false, nil then nil
          else %(#{k}="#{ERB::Util.html_escape(v)}")
          end
        end.compact.join(' ').html_safe
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def editor_attributes
        attrs = {}
        attrs['class'] = 'lexxy-content'
        attrs['name'] = @name if @name.present?
        attrs['value'] = @value if @value.present?
        attrs['placeholder'] = @placeholder if @placeholder.present?
        attrs['preset'] = @preset if @preset.present?

        # Boolean attributes - only include when non-default
        attrs['toolbar'] = 'false' if @toolbar == false
        attrs['toolbar'] = @toolbar if @toolbar.is_a?(String)
        attrs['attachments'] = 'false' unless @attachments
        attrs['markdown'] = true if @markdown
        attrs['multiLine'] = 'false' unless @multi_line
        attrs['richText'] = 'false' unless @rich_text

        # Standard HTML boolean attributes
        attrs['required'] = true if @required
        attrs['disabled'] = true if @disabled
        attrs['autofocus'] = true if @autofocus

        # Active Storage direct upload URLs (required for image/file attachments)
        if @attachments
          attrs['data-direct-upload-url'] = direct_upload_url
          attrs['data-blob-url-template'] = blob_url_template
        end

        # Pass-through data attributes (can override upload URLs if needed)
        @options.fetch(:data, {}).each do |key, val|
          attrs["data-#{key}"] = val
        end

        attrs
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def direct_upload_url
        helpers.main_app.rails_direct_uploads_url
      rescue NoMethodError
        nil
      end

      def blob_url_template
        helpers.main_app.rails_service_blob_url(':signed_id', ':filename')
      rescue NoMethodError
        nil
      end
    end
  end
end
