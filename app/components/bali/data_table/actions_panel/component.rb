# frozen_string_literal: true

module Bali
  module DataTable
    module ActionsPanel
      class Component < ApplicationViewComponent
        include Bali::Utils::Url

        def initialize(
          filter_form:,
          url:,
          export_formats: [],
          display_mode: :table,
          display_mode_param_name: :data_display_mode,
          grid_display_mode_enabled: false
        )
          @filter_form = filter_form
          @url = url
          @export_formats = Array.wrap(export_formats).compact
          @display_mode = display_mode
          @grid_display_mode_enabled = grid_display_mode_enabled
          @display_mode_param_name = display_mode_param_name
        end

        def url(query_params = {})
          add_query_params(@url, { q: @filter_form.query_params }.merge(query_params))
        end
      end
    end
  end
end
