# frozen_string_literal: true

module Bali
  module DataTable
    module GroupByControl
      # GroupByControl renders the "Agrupar por" dropdown for a DataTable.
      #
      # It is a Bali::Dropdown of LINKS (not a form): each option links to the
      # current URL with `group_by` merged into the existing query parameters, so
      # every active filter/search/sort param is preserved naturally. The
      # "no grouping" option removes the param. The `page` param is dropped on
      # every link so switching grouping returns to the first page.
      #
      # Auto-configured by DataTable from a FilterForm that declares
      # `group_by_attribute`.
      class Component < ApplicationViewComponent
        # @param url [String] Base URL for the option links (typically request.path)
        # @param filter_form [Bali::FilterForm] Form exposing group_by_options / group_by
        # @param current_params [Hash] Current query params to preserve (merged into links)
        # @param options [Array<Hash>] Explicit {attribute:, label:} options — for surfaces
        #   whose grouping no vive en un FilterForm (p.ej. un Gantt server-rendered). Gana
        #   sobre las del form.
        # @param current [String, Symbol] Explicit current grouping value (pairs with options:)
        # @param param [String] Query param that carries the grouping (default "group_by")
        # @param include_none [Boolean] Whether to offer the "no grouping" item
        # @param label [String] Trigger label override (defaults to the i18n "Group by")
        def initialize(url:, filter_form: nil, current_params: {}, options: nil, current: nil,
                       param: "group_by", include_none: true, label: nil)
          @url = url
          @filter_form = filter_form
          @current_params = (current_params || {}).to_h.with_indifferent_access
          @options = options
          @current = current
          @param = param.to_s
          @include_none = include_none
          @label = label
        end

        attr_reader :param

        def render?
          options.present?
        end

        def options
          @options || @filter_form&.group_by_options || []
        end

        def include_none?
          @include_none
        end

        def current_value
          (@current || @filter_form&.group_by).to_s
        end

        def active?
          current_value.present?
        end

        def trigger_label
          return label unless active?

          current = options.find { |option| option[:attribute].to_s == current_value }
          resolved = current&.dig(:label) || current_value.humanize
          "#{label}: #{resolved}"
        end

        def option_href(attribute)
          build_href(attribute.to_s)
        end

        def no_grouping_href
          build_href(nil)
        end

        def option_active?(attribute)
          active? && current_value == attribute.to_s
        end

        def label
          @label || I18n.t("view_components.bali.data_table.group_by_control.label", default: "Group by")
        end

        def no_grouping_label
          I18n.t("view_components.bali.data_table.group_by_control.no_grouping", default: "No grouping")
        end

        def item_class(selected)
          "text-primary font-medium" if selected
        end

        private

        # Merge (or drop) the grouping param into the preserved params and build the URL.
        # `page` is always dropped so grouping changes reset pagination, and the one-shot
        # commands (`clear_filters`/`clear_search`) never ride along: they are actions, not
        # navigation state, and carrying them re-executed the wipe on every later click.
        def build_href(group_by)
          params = @current_params.except("page", "clear_filters", "clear_search", param)
          params = params.merge(param => group_by) unless group_by.nil?
          query = params.to_query
          query.present? ? "#{@url}?#{query}" : @url
        end
      end
    end
  end
end
