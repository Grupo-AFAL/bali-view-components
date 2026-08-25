# frozen_string_literal: true

module DemoWidgets
  # The `visible?` demo: hidden unless the catalog actually has an active
  # studio to show. A tenant that hasn't onboarded one yet doesn't get a
  # permanently empty tile — it gets no tile, the same way a host would hide a
  # widget behind a role or a feature flag that hasn't been turned on yet.
  class ActiveStudios < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :medium

    def visible? = Studio.active.exists?

    def call
      list_from(Studio.active.order(:name), view_all_path: admin_studios_path)
    end

    private

    def row(studio)
      Bali::Widget::Row.new(
        title: studio.name,
        subtitle: subtitle(studio.country, studio.size&.humanize),
        href: admin_studio_path(studio)
      )
    end
  end
end
