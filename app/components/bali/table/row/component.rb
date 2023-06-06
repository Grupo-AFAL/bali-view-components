# frozen_string_literal: true

module Bali
  module Table
    module Row
      class Component < ApplicationViewComponent
        class IncompatileOptions < StandardError; end

        def initialize(record_id: nil, skip_tr: false, bulk_actions: false, **options)
          @record_id = record_id
          @skip_tr = skip_tr
          @bulk_actions = bulk_actions
          @options = hyphenize_keys(options)

          if @bulk_actions && @record_id.blank?
            raise IncompatileOptions, 'record_id is required when bulk_actions is true'
          end

          return unless @skip_tr && @bulk_actions

          raise IncompatileOptions, 'skip_tr and bulk_actions are mutually exclusive'
        end
      end
    end
  end
end
