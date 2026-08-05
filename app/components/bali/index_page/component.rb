# frozen_string_literal: true

module Bali
  module IndexPage
    # Toda la superficie (title, subtitle, breadcrumbs, back, max_width, sidebar_width, y los
    # slots nav, title_tags, body, sidebar, actions) vive en PageComponents::Shared.
    class Component < ApplicationViewComponent
      include PageComponents::Shared
    end
  end
end
