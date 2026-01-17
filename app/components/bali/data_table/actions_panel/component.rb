# frozen_string_literal: true

module Bali
  module DataTable
    module ActionsPanel
      class Component < ApplicationViewComponent
        include Bali::Utils::Url

        renders_many :actions, ->(method: :get, href: nil, **options) do
          Bali::DataTable::Action::Component.new(
            method: method, href: build_url(url: href), **options
          )
        end

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
          @display_mode = display_mode&.to_sym
          @grid_display_mode_enabled = grid_display_mode_enabled
          @display_mode_param_name = display_mode_param_name
        end

        def build_url(query_params = {}, url: nil)
          base_params = @filter_form ? { q: @filter_form.query_params } : {}
          add_query_params(url || @url, base_params.merge(query_params))
        end

        def single_export?
          @export_formats.size == 1
        end

        def multiple_exports?
          @export_formats.size > 1
        end

        def show_display_mode_separator?
          @grid_display_mode_enabled && @export_formats.any?
        end

        def table_mode_active?
          @display_mode == :table
        end

        def grid_mode_active?
          @display_mode == :grid
        end

        def single_export_format
          @export_formats.first
        end

        def table_mode_url
          build_url(@display_mode_param_name => :table)
        end

        def grid_mode_url
          build_url(@display_mode_param_name => :grid)
        end

        def table_button_classes
          class_names(
            'join-item btn btn-ghost btn-sm btn-square',
            'btn-active' => table_mode_active?
          )
        end

        def grid_button_classes
          class_names(
            'join-item btn btn-ghost btn-sm btn-square',
            'btn-active' => grid_mode_active?
          )
        end
      end
    end
  end
end
