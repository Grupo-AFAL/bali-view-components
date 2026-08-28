# frozen_string_literal: true

module Bali
  module Widget
    # Turns request params into the arrays `Bali::DashboardWidget::Store` takes.
    #
    #   store.arrange(Bali::Widget::Layout.from(params, offering: offering))
    #   store.choose(Bali::Widget::Layout.chosen(params, offering: offering))
    #
    # THE SECURITY BOUNDARY, and the reason it is library code. Bali ships no
    # controller — who may see which widget is the host's rule — but that argues
    # for parameterising this by `offering:`, not for every host retyping it. The
    # filtering was a dozen lines in a documentation example, copied into each
    # app, and it is the entire security property of the feature.
    #
    # `offering` is GATED HERE rather than assumed to arrive gated. A submitted
    # key becomes a widget only by being found in the authorized set, so an
    # unauthorized, retired or hand-edited key finds nothing. Safe by
    # CONSTRUCTION rather than by convention: there is no permitted-key list to
    # pass, and no host call to forget. `Bali::Widget.authorized_for` is
    # idempotent, so a host that filters first pays nothing.
    #
    # Silently DROPPED rather than rejected. A role revoked between rendering the
    # page and submitting it should degrade quietly, not 422 — and refusing a
    # made-up key would confirm which keys are real.
    class Layout
      class << self
        # An ordered `[{ widget:, size: }, …]` for `Store#arrange`, from the
        # `widgets[][key]` / `widgets[][size]` payload the grid sends.
        #
        # An EMPTY submission returns `[]`, which `arrange` reads as a reset —
        # removing the last card sends nothing, and no rows means "never chose".
        # Checked before any parsing, because `ActionController::Parameters#expect`
        # raises on both an omitted key and an empty array, and only one of those
        # is an error.
        def from(params, offering:)
          submitted = params[:widgets]
          return [] if submitted.blank?

          by_key = Bali::Widget.authorized_for(offering).index_by(&:key)
          submitted.filter_map do |item|
            widget = by_key[item[:key].to_s]
            { widget: widget, size: item[:size].presence } if widget
          end
        end

        # The widgets for `Store#choose`, from a picker's `widget_keys[]`.
        # Membership only — `choose` decides order and preserves stored sizes.
        def chosen(params, offering:, key: :widget_keys)
          by_key = Bali::Widget.authorized_for(offering).index_by(&:key)
          Array(params[key]).filter_map { |submitted| by_key[submitted.to_s] }
        end
      end
    end
  end
end
