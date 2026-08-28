# frozen_string_literal: true

module DemoWidgets
  # The `visible?` demo: hidden unless the catalog actually has an active studio
  # to show. A tenant that has not onboarded one does not get a permanently empty
  # tile — it gets no tile, the same way a host hides a widget behind a role.
  class ActiveStudios < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :medium

    # title "Active Studios"
    # description "List of active studios"
    # empty_message "No active studios"

    list scope: Studio.active, limit: 10, order_by: :name
    # row_serializer ¿?
    # view_all_path

    row_title :name
    row_subtitle { |studio| subtitle(studio.country, studio.size&.humanize) }
    row_href { |studio| admin_studio_path(studio) }
    view_all_path { admin_studios_path }

    # Costs one `EXISTS` — never a widget query.
    def visible? = Studio.active.exists?
  end
end
