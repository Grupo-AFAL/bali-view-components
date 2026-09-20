# frozen_string_literal: true

module DemoWidgets
  # THE EMPTY LIST. A real scope that legitimately matches nothing, so the card
  # has somewhere to show the muted empty message rather than a blank region —
  # and no "view all" link, because `view_all_link?` requires something to view.
  class IndieStudios < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :medium

    list { Studio.where(indie: true).order(:name) }

    row do |r|
      r.title :name
      r.subtitle { |studio| join(studio.country, studio.size.presence&.humanize) }
      r.href { |studio| admin_studio_path(studio) }
    end

    view_all_path { admin_studios_path }
  end
end
