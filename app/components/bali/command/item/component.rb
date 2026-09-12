# frozen_string_literal: true

module Bali
  module Command
    module Item
      class Component < ApplicationViewComponent
        # @param title [String] Primary label.
        # @param meta [String, nil] Secondary metadata (e.g. id, status, owner).
        # @param icon [String, nil] Lucide icon name to render in the leading slot.
        # @param href [String, nil] Navigate to this URL when activated.
        # @param mode [Symbol] :searchable | :navigation | :recent | :action —
        #   inherited from group.
        # @param search [String, nil] Override the searchable text. Defaults to
        #   "title meta" — title-and-meta concatenated for substring matching.
        # @param options [Hash] Extra HTML attributes (class, data, id, aria-*)
        #   merged onto the row button — the passthrough the slot lambda promises.
        def initialize(title:, meta: nil, icon: nil, href: nil,
                       mode: :searchable, search: nil, **options)
          @title = title
          @meta = meta
          @icon = icon
          @href = href
          @mode = mode
          @search = search || [ title, meta ].compact.join(" ")
          @options = options
        end

        attr_reader :title, :meta, :icon, :href, :mode, :search

        # The row button's attributes, with the host's `**options` merged in:
        # `class` composes with the row classes, `data` merges over the row's own
        # command-target/action data, and anything else passes straight through.
        def button_options
          options = @options.dup
          {
            type: "button",
            class: class_names(ROW_CLASSES, options.delete(:class)),
            data: row_data.merge(options.delete(:data) || {})
          }.merge(options)
        end

        private

        ROW_CLASSES = "cmd-row group flex items-center gap-2.5 w-full rounded-md " \
                      "text-left text-sm text-base-content cursor-pointer"

        def row_data
          { command_target: "row", mode: mode, href: href,
            search: search.downcase, action: "click->command#select" }.compact
        end
      end
    end
  end
end
