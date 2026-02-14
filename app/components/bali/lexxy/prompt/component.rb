# frozen_string_literal: true

module Bali
  module Lexxy
    module Prompt
      class Component < ApplicationViewComponent
        # rubocop:disable Metrics/ParameterLists
        def initialize(trigger:, name:, src: nil, remote_filtering: false,
                       insert_editable_text: false, empty_results: nil,
                       supports_space_in_searches: false, **options)
          @trigger = trigger
          @name = name
          @src = src
          @remote_filtering = remote_filtering
          @insert_editable_text = insert_editable_text
          @empty_results = empty_results
          @supports_space_in_searches = supports_space_in_searches
          @options = options
        end
        # rubocop:enable Metrics/ParameterLists

        def call
          content_tag('lexxy-prompt', content, prompt_attributes)
        end

        private

        def prompt_attributes
          attrs = { trigger: @trigger, name: @name }
          attrs[:src] = @src if @src.present?
          attrs[:'remote-filtering'] = '' if @remote_filtering
          attrs[:'insert-editable-text'] = '' if @insert_editable_text
          attrs[:'supports-space-in-searches'] = '' if @supports_space_in_searches
          attrs[:'empty-results'] = @empty_results if @empty_results.present?
          attrs.merge!(@options)
          attrs
        end
      end
    end
  end
end
