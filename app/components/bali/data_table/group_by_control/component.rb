# frozen_string_literal: true

module Bali
  module DataTable
    module GroupByControl
      # GroupByControl renders the "Group by" dropdown for a DataTable.
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
        include Bali::DataTable::ToolbarHref

        # @param url [String] Base URL for the option links (typically request.path)
        # @param filter_form [Bali::FilterForm] Form exposing group_by_options / group_by
        # @param current_params [Hash] Current query params to preserve (merged into links)
        # @param options [Array<Hash>] Explicit {attribute:, label:} options — for surfaces
        #   whose grouping does not live in a FilterForm (e.g. a server-rendered roadmap).
        #   Wins over the form's.
        # @param current [String, Symbol] Explicit current grouping value (pairs with options:)
        # @param param [String] Query param that carries the grouping (default "group_by")
        # @param include_none [Boolean] Whether to offer the "no grouping" item
        # @param label [String] Trigger label override (defaults to the i18n "Group by")
        # @param disabled [Boolean] Render the control INERT instead of hiding it. Used when
        #   the current display mode does not apply grouping: hiding it moved the toolbar when
        #   switching modes and left no explanation for why the control had disappeared.
        def initialize(url:, filter_form: nil, current_params: {}, options: nil, current: nil,
                       param: "group_by", include_none: true, label: nil, disabled: false)
          @disabled = disabled
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

        def disabled? = @disabled

        # Why it is inert. Goes in `title` and not as a notice in the row: the disabled
        # button already communicates the state, and a permanent text there competed with
        # the filters.
        def disabled_title
          I18n.t("bali_view.data_table.group_by_control.disabled_title",
                 modes: disabled_modes)
        end

        # `humanize` here is the extension point, not a missing translation: the
        # display modes a listing declares are the HOST's, and Bali only ships
        # names for the four it previews. Without the lookup the whole sentence
        # came out half-translated — a Spanish `disabled_title` interpolating an
        # English "Cards".
        def disabled_modes
          modes = @filter_form.respond_to?(:group_by_modes) ? @filter_form.group_by_modes : []
          modes.map do |mode|
            I18n.t("bali_view.data_table.display_modes.#{mode}", default: mode.to_s.humanize)
          end.to_sentence
        end

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

        # `""` and not `nil`: the param stays in the URL, empty. Dropping it made "no
        # grouping" indistinguishable from "nothing came in", and a listing with filter
        # persistence restores from the cache what the URL does not say — that is, turning
        # grouping off resurrected it in the same render (see
        # FilterForm#fetch_stored_filter_state).
        #
        # Where a `group_by_attribute default:` is declared, empty is not enough either: see
        # Bali::FilterForm::GroupByConfiguration::NO_GROUPING_VALUE.
        def no_grouping_href
          build_href(no_grouping_value)
        end

        # @return [String] how this listing spells "no grouping" in the URL
        def no_grouping_value
          @filter_form.try(:no_grouping_value) || ""
        end

        def option_active?(attribute)
          active? && current_value == attribute.to_s
        end

        def label
          @label || I18n.t("bali_view.data_table.group_by_control.label")
        end

        def no_grouping_label
          I18n.t("bali_view.data_table.group_by_control.no_grouping")
        end

        def item_class(selected)
          "text-primary font-medium" if selected
        end

        private

        # Merge (or drop) the grouping param into the preserved params. See ToolbarHref for
        # why `page`/`clear_*` never ride along and why the base URL is parsed instead of
        # concatenated.
        def build_href(group_by)
          build_toolbar_href(@url, @current_params, param, group_by)
        end
      end
    end
  end
end
