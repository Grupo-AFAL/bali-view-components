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
        def initialize(url:, filter_form:, current_params: {})
          @url = url
          @filter_form = filter_form
          @current_params = (current_params || {}).to_h.with_indifferent_access
        end

        def render?
          options.present?
        end

        def options
          @filter_form.group_by_options
        end

        def active?
          @filter_form.group_by_active?
        end

        def trigger_label
          return label unless active?

          current = options.find { |option| option[:attribute].to_s == @filter_form.group_by.to_s }
          resolved = current&.dig(:label) || @filter_form.group_by.to_s.humanize
          "#{label}: #{resolved}"
        end

        def option_href(attribute)
          build_href(attribute.to_s)
        end

        def no_grouping_href
          build_href(nil)
        end

        def option_active?(attribute)
          active? && @filter_form.group_by.to_s == attribute.to_s
        end

        def label
          I18n.t("view_components.bali.data_table.group_by_control.label", default: "Group by")
        end

        def no_grouping_label
          I18n.t("view_components.bali.data_table.group_by_control.no_grouping", default: "No grouping")
        end

        def item_class(selected)
          "text-primary font-medium" if selected
        end

        private

        # Merge (or drop) group_by into the preserved params and build the URL.
        # `page` is always dropped so grouping changes reset pagination.
        def build_href(group_by)
          params = @current_params.except("page", "group_by")
          params = params.merge("group_by" => group_by) unless group_by.nil?
          query = params.to_query
          query.present? ? "#{@url}?#{query}" : @url
        end
      end
    end
  end
end
