# frozen_string_literal: true

module Bali
  module SplitView
    module List
      module Item
        # One row of a structured SplitView list. Never rendered directly — it comes
        # from `list.with_item(...)`, which is what lets the component write the four
        # attributes that used to be the host's job: `data-turbo-frame`,
        # `data-split-view-target`, `data-action` and `aria-current`.
        #
        # The fields are the ones that appear in both master-detail listings this was
        # generalised from (see docs/guides/master-detail.md for the comparison):
        # a leading icon, a title, a subtitle, any number of tags, and a trailing
        # meta column that can be coloured for an overdue date. Anything else goes in
        # the block, which renders under the subtitle.
        class Component < ApplicationViewComponent
          TITLE_CLASSES = "font-medium text-sm text-base-content leading-snug truncate"
          SUBTITLE_CLASSES = "text-xs text-base-content/60 truncate"
          META_CLASSES = "text-xs shrink-0 whitespace-nowrap"

          # Only the colours a listing actually needs on a trailing date or count.
          # `nil` is the neutral default; `:error` is the overdue case both source
          # listings paint red.
          META_COLORS = {
            error: "text-error font-medium",
            warning: "text-warning font-medium",
            success: "text-success",
            primary: "text-primary"
          }.freeze

          renders_many :tags, lambda { |text:, color: nil, **options|
            Bali::Tag::Component.new(text: text, color: color, size: :sm, **options)
          }

          attr_reader :title, :subtitle, :icon, :meta, :href

          # frame_id / selected_id are injected by the list; a caller never passes them.
          def initialize(href:, title:, frame_id: nil, selected_id: nil, id: nil,
                         subtitle: nil, icon: nil, meta: nil, meta_color: nil, **options)
            @href = href
            @title = title
            @frame_id = frame_id
            @selected_id = selected_id
            @id = id
            @subtitle = subtitle
            @icon = icon
            @meta = meta
            @meta_color = meta_color
            @options = options
          end

          def selected?
            @id.present? && @selected_id.present? && @id.to_s == @selected_id.to_s
          end

          private

          attr_reader :options

          def meta_classes
            class_names(META_CLASSES, META_COLORS[@meta_color&.to_sym] || "text-base-content/60")
          end

          def link_attributes
            options.except(:class, :data, :aria).deep_merge(
              class: class_names("split-view-row split-view-item", options[:class]),
              # The wiring. A host writing these by hand is the boilerplate this
              # component exists to delete, so they are not overridable here.
              data: (options[:data] || {}).merge(
                turbo_frame: @frame_id,
                split_view_target: "row",
                action: "click->split-view#select"
              ),
              aria: (options[:aria] || {}).merge(current: (selected? ? "true" : nil))
            ).tap { |attributes| attributes[:id] = dom_id if @id.present? && !options.key?(:id) }
          end

          def dom_id
            [ @frame_id, "item", @id ].compact.join("-")
          end
        end
      end
    end
  end
end
