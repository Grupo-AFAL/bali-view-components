# frozen_string_literal: true

module Bali
  module SplitView
    module List
      module Group
        # A run of rows under one heading, with the group's own total next to it.
        # Never rendered directly — it comes from `list.with_group(...)`, and its
        # rows come from `group.with_item(...)`, which takes exactly what
        # `list.with_item` takes.
        #
        # **`key:` is the contract with infinite scroll.** It is written onto the
        # element as `data-split-view-group-key`, and it is how the controller
        # recognises the group that an appended page continues: a page arrives as
        # its own set of groups, and the first of them is usually the same group
        # the list already ends with. Without the key the reader would get the
        # heading twice, once per page.
        #
        # **The count is the group's TOTAL, not the number of rows on screen.**
        # The server knows it (a `GROUP BY` count); the client cannot, because it
        # only ever holds the pages loaded so far. That is what keeps the number
        # honest while rows keep arriving under it, and it is why the header needs
        # no updating when a page merges in.
        class Component < ApplicationViewComponent
          HEADER_CLASSES = "split-view-group-header"
          COUNT_CLASSES = "split-view-group-count"

          # frame_id / selected_id are injected by the list, exactly as they are
          # for an ungrouped `with_item`, so a row inside a group is wired the
          # same as a row outside one.
          renders_many :items, lambda { |**options, &block|
            Bali::SplitView::List::Item::Component.new(
              frame_id: @frame_id, selected_id: @selected_id, **options
            )
          }

          attr_reader :key, :label, :count

          def initialize(key:, label: nil, count: nil, frame_id: nil, selected_id: nil, **options)
            @key = key
            @label = label
            @count = count
            @frame_id = frame_id
            @selected_id = selected_id
            @options = options

            return if @key.present?

            raise ArgumentError,
                  "with_group needs a `key:`. It is what tells an appended page that its " \
                  "first group continues the one already on screen; without it the second " \
                  "page repeats the heading."
          end

          # The heading's own id, so the group can be named by the text a sighted
          # reader sees rather than by a second copy of it in an `aria-label`,
          # which screen readers would then announce twice.
          def header_id
            [ @frame_id, "group", key.to_s.parameterize.presence || "item" ].compact.join("-")
          end

          private

          attr_reader :options

          def container_attributes
            options.except(:class, :data, :aria).merge(
              class: class_names("split-view-group", options[:class]),
              # `role="group"` and not a landmark: this is a run of rows inside a
              # list, not a region of the page, and a landmark per group would
              # clutter the rotor of an inbox with twenty of them.
              role: "group",
              aria: (options[:aria] || {}).merge(labelledby: header_id),
              data: (options[:data] || {}).merge(split_view_group_key: key.to_s)
            )
          end
        end
      end
    end
  end
end
