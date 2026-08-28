# frozen_string_literal: true

module DemoWidgets
  # The `visible?` demo: hidden unless the catalog actually has an active studio
  # to show. A tenant that has not onboarded one does not get a permanently empty
  # tile — it gets no tile, the same way a host hides a widget behind a role.
  class ActiveStudios < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :medium

    list { Studio.active.order(:name) }

    row do |r|
      r.title :name
      r.subtitle { |studio| join(studio.country, studio.size&.humanize) }
      r.href { |studio| admin_studio_path(studio) }
    end
    view_all_path { admin_studios_path }

    # Costs one `EXISTS` — never a widget query.
    def visible? = Studio.active.exists?
  end
end
