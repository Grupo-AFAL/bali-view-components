# frozen_string_literal: true

module Bali
  module Filters
    module PersistenceToggle
      # The bookmark that decides whether filters are remembered between visits.
      #
      # It lives on its own and not inside the filter panel because in the DataTable toolbar
      # it is a control of its own —"how state is remembered"— and not a panel button. Hosts
      # using Filters/SimpleFilters without DataTable still get it from there.
      #
      # INVARIANT: ONE toggle per listing. Two `filter-persistence` controllers over the same
      # storage_id trample each other's localStorage and cookie, and the second one leaves the
      # user with no way to know which of the two is in charge.
      class Component < ApplicationViewComponent
        # @param storage_id [String] The listing's identity; without it there is nowhere to save
        # @param enabled [Boolean] Whether the user has already opted into persisting
        def initialize(storage_id:, enabled: false)
          @storage_id = storage_id
          @enabled = enabled
        end

        attr_reader :storage_id

        def render?
          storage_id.present?
        end

        def enabled?
          @enabled
        end

        # EXISTING `bali.filters.*` keys, read through an explicit `I18n.t` and NOT through
        # `t('.x')`: the ViewComponent helper resolves to the sidecar scope
        # (`view_components.bali.filters.persistence_toggle.*`), so using it here would move
        # the keys and silently leave any host that has them overridden untranslated.
        def enabled_tooltip
          I18n.t("bali_view.filters.persistence_enabled")
        end

        def disabled_tooltip
          I18n.t("bali_view.filters.persistence_disabled")
        end

        def tooltip
          enabled? ? enabled_tooltip : disabled_tooltip
        end

        def label
          I18n.t("bali_view.filters.persistence_label")
        end
      end
    end
  end
end
