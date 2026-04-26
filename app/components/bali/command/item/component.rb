# frozen_string_literal: true

module Bali
  module Command
    module Item
      class Component < ApplicationViewComponent
        # @param title [String] Primary label.
        # @param meta [String, nil] Secondary metadata (e.g. id, status, owner).
        # @param icon [String, nil] Lucide icon name to render in the leading slot.
        # @param href [String, nil] Navigate to this URL when activated.
        # @param mode [Symbol] :searchable | :recent | :action — inherited from group.
        # @param search [String, nil] Override the searchable text. Defaults to
        #   "title meta" — title-and-meta concatenated for substring matching.
        def initialize(title:, meta: nil, icon: nil, href: nil,
                       mode: :searchable, search: nil)
          @title = title
          @meta = meta
          @icon = icon
          @href = href
          @mode = mode
          @search = search || [ title, meta ].compact.join(" ")
        end

        attr_reader :title, :meta, :icon, :href, :mode, :search
      end
    end
  end
end
