# frozen_string_literal: true

module Bali
  module SideMenu
    module List
      class Component < ApplicationViewComponent
        renders_many :items, Item::Component.renderable

        # Mirrors Bali::SideMenu::Item::Component::BADGE_COLOR_CLASSES so a section
        # badge looks identical to the badges rendered on individual items.
        BADGE_COLOR_CLASSES = {
          primary: "border-primary/20 bg-primary/10 text-primary",
          secondary: "border-secondary/20 bg-secondary/10 text-secondary",
          accent: "border-accent/20 bg-accent/10 text-accent",
          success: "border-success/20 bg-success/10 text-success",
          warning: "border-warning/20 bg-warning/10 text-warning",
          error: "border-error/20 bg-error/10 text-error",
          info: "border-info/20 bg-info/10 text-info"
        }.freeze

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

        def title_classes
          class_names("menu-label", "flex", "items-center", "px-2.5", "pt-3", "pb-1.5", @title_class)
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
