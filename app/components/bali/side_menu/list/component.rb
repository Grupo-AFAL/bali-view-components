# frozen_string_literal: true

module Bali
  module SideMenu
    module List
      class Component < ApplicationViewComponent
        renders_many :items, Item::Component.renderable

        BADGE_COLOR_CLASSES = Item::Component::BADGE_COLOR_CLASSES

        attr_reader :title, :badge

        def initialize(current_path:, title: nil, group_behavior: :expandable, **options)
          @title = title
          @current_path = current_path
          @group_behavior = group_behavior
          @title_class = options.delete(:title_class)
          @badge = options.delete(:badge)
          @badge_color = options.delete(:badge_color) || :primary
          @options = options
        end

        # `flex` deliberately absent: the collapsed sidebar hides the label with
        # `.menu-label { @apply hidden }`, and since #693 that rule lives in
        # @layer components where a utility on the element would beat it. The
        # display value is set in ../index.css instead.
        def title_classes
          class_names("menu-label", "items-center", "px-2.5", "pt-3", "pb-1.5", @title_class)
        end

        def badge_classes
          class_names(
            "border",
            "rounded-box",
            "px-1.5",
            "text-[12px]",
            BADGE_COLOR_CLASSES[@badge_color]
          )
        end

        # Uses inline <span> elements (not <div> like the item badge) because the
        # section title is a <p>, which cannot legally contain block-level children.
        # The visual style stays identical via the shared badge classes.
        def render_badge
          return unless badge.present?

          tag.span(class: "ms-auto inline-flex gap-2") do
            tag.span(badge, class: badge_classes)
          end
        end
      end
    end
  end
end
