# frozen_string_literal: true

module Bali
  module DataTable
    module ViewSwitchControl
      # The DataTable's view segmented control. It wraps Bali::ViewSwitch and adds the one
      # thing the generic switch cannot know: what THIS listing's URL looks like.
      #
      # Every view declares `value:` (what travels in `?view=`) and the href is built by
      # ToolbarHref merging the current query string: `page` is dropped (switching views goes
      # back to the first one) and filters, search, sorting and grouping survive.
      #
      # `saved_view` DOES travel here, the opposite of Bali::Filters (EXCLUDED_PARAMS). There
      # it is a filter SUBMIT: resending it made the server re-apply the view's payload on top
      # of what the user had just typed (#669). Here it is NAVIGATION: switching display mode
      # without leaving the saved view is exactly what is expected.
      #
      # The name is ViewSwitchControl and not ViewSwitch (GroupByControl's convention): inside
      # `module Bali::DataTable` the constant `ViewSwitch::Component` would shadow
      # `Bali::ViewSwitch::Component`.
      class Component < ApplicationViewComponent
        include Bali::DataTable::ToolbarHref

        View = Struct.new(:name, :icon, :value, :href, :active, :options, keyword_init: true)

        MISSING_TARGET_MESSAGE = "with_view needs `value:` (a view on this same route) " \
          "or `href:` (a view that lives on another route)."

        # @param url [String] Base URL of the listing (the DataTable's own `url:`)
        # @param current_params [Hash] current query params, preserved on every link
        # @param param [String, Symbol] param that carries the view (default "view")
        # @param current [Symbol, String, nil] requested view, RAW: validated against the
        #   declared views (see #current_value)
        # @param aria_label [String] accessible label of the group (i18n default)
        # @param options [Hash] passed through as-is to Bali::ViewSwitch (size:, icon_only:, class:)
        def initialize(url:, current_params: {}, param: :view, current: nil, aria_label: nil, **options)
          @url = url.to_s
          @current_params = (current_params || {}).to_h.with_indifferent_access
          @param = param.to_s
          @current = current
          @aria_label = aria_label
          @options = options
          @views = []
        end

        attr_reader :views, :param, :options

        # Slot DSL: dt.with_view_switch { |vs| vs.with_view(name:, icon:, value:) }
        def with_view(name:, icon:, value: nil, href: nil, active: nil, **view_options)
          raise ArgumentError, MISSING_TARGET_MESSAGE if value.nil? && href.nil?

          @views << View.new(name: name, icon: icon, value: value&.to_sym,
                             href: href, active: active, options: view_options)
          self
        end

        def render?
          views.any?
        end

        def aria_label
          @aria_label || t(".aria_label")
        end

        # Values of the views that live on THIS route (the ones that carry `value:`).
        def declared_values
          @declared_values ||= views.filter_map(&:value)
        end

        # The raw `?view=` never reaches the content without going through the list of
        # declared views: an unknown value falls back to the first one instead of leaving the
        # listing empty. Same boundary as FilterForm#resolve_group_by.
        def current_value
          return @current&.to_sym if declared_values.empty?

          declared_values.include?(@current&.to_sym) ? @current.to_sym : declared_values.first
        end

        def view_attributes(view)
          {
            name: view.name,
            icon: view.icon,
            href: view.href || href_for(view.value),
            active: resolve_active(view),
            **view.options
          }
        end

        private

        # A view with its own `href:` (another route) is not marked here: Bali::ViewSwitch's
        # path autodetection is the one that knows whether we are standing on it.
        def resolve_active(view)
          return view.active unless view.active.nil?
          return nil if view.value.nil?

          view.value == current_value
        end

        def href_for(value)
          build_toolbar_href(@url, @current_params, param, value.to_s)
        end
      end
    end
  end
end
