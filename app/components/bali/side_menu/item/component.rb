# frozen_string_literal: true

module Bali
  module SideMenu
    module Item
      class Component < ApplicationViewComponent
        MATCH_TYPES = %i[exact partial starts_with crud].freeze

        # Returns a lambda for use with renders_many that builds Item components.
        # The lambda is evaluated in the host component's context, so @current_path
        # and @group_behavior resolve to the host's instance variables.
        def self.renderable(group_behavior: nil)
          lambda { |href: nil, name: nil, icon: nil,
                    authorized: true, disabled: false, target: nil, **options|
            Item::Component.new(
              name: name,
              href: href,
              icon: icon,
              authorized: authorized,
              disabled: disabled,
              target: target,
              current_path: @current_path,
              group_behavior: group_behavior || @group_behavior,
              **options
            )
          }
        end

        renders_many :items, renderable

        attr_reader :name, :icon, :badge, :href, :target

        def initialize(current_path:, href: nil, name: nil, icon: nil, authorized: true,
                       group_behavior: :expandable, disabled: false, target: nil, **options)
          @name = name
          @href = href
          @icon = icon
          @authorized = authorized
          @current_path = current_path
          @group_behavior = Bali::SideMenu::Component::GROUP_BEHAVIORS.include?(group_behavior) ? group_behavior : :expandable
          @disabled = disabled
          @target = target
          @active = options.delete(:active)
          @match_type = MATCH_TYPES.include?(options[:match]) ? options.delete(:match) : :exact
          @active_when = options.delete(:active_when)
          @badge = options.delete(:badge)
          @badge_color = options.delete(:badge_color) || :primary
          @link_class = options.delete(:class)
          @options = options
        end

        def render?
          @authorized
        end

        def subitems?
          items.present?
        end

        def disabled?
          @disabled || @href.blank?
        end

        def active?
          return @active unless @active.nil?

          (!disabled? && active_path?(parsed_path, @current_path, match: @match_type)) ||
            active_when_match? ||
            active_child_items?
        end

        # OR-ed into +active?+ so an item declaring +active_when:+ stays
        # highlighted on nested full-page routes that +match:+ alone misses.
        def active_when_match?
          active_extra_path?(@active_when, @current_path)
        end

        def active_child_items?
          items.reject(&:disabled?).any?(&:active?)
        end

        def expandable_mode?
          @group_behavior == :expandable
        end

        def dropdown_mode?
          @group_behavior == :dropdown
        end

        def menu_item_classes
          class_names(
            "menu-item",
            "group",
            { "active" => active? && !subitems? },
            @link_class
          )
        end

        def collapse_title_classes
          class_names(
            "collapse-title",
            "px-2.5",
            "py-1.5",
            { "active" => active? }
          )
        end

        # Translated aria-label for collapse toggle
        def toggle_label
          I18n.t("bali.side_menu.toggle_item", name: name, default: "Toggle #{name}")
        end

        def render_badge
          return unless badge.present?

          tag.div(class: "ms-auto inline-flex gap-2") do
            tag.div(badge, class: badge_classes)
          end
        end

        def render_icon
          return unless icon.present?

          render Bali::Icon::Component.new(icon, class: "size-4")
        end

        def render_initial_icon
          tag.span(
            (content || name)&.to_s&.first&.upcase,
            class: "size-4 flex items-center justify-center text-xs font-medium"
          )
        end

        def render_icon_or_initial
          icon.present? ? render_icon : render_initial_icon
        end

        def render_collapsed_tooltip(tooltip_href: nil)
          render Bali::Tooltip::Component.new(placement: :right, class: "side-menu-collapsed hidden") do |tooltip|
            tooltip.with_trigger do
              tag.a(
                href: tooltip_href || href.presence || "#",
                class: class_names("menu-item", "active" => active?),
                target: target, rel: rel
              ) { render_icon_or_initial }
            end
            content || name
          end
        end

        # Class chain for the collapsed-state flyout container.
        # Combines our own visibility scope (`side-menu-collapsed hidden`)
        # with DaisyUI's hover dropdown.
        def flyout_classes
          class_names(
            "side-menu-collapsed-flyout",
            "side-menu-collapsed",
            "hidden",
            "dropdown",
            "dropdown-right",
            "dropdown-hover"
          )
        end

        # Flat link for a child entry inside a popup. Both the
        # `:dropdown` mode template and the `:expandable` collapsed-state
        # flyout render children this way so a popup doesn't recurse
        # into nested accordions or flyouts.
        def render_subitem_link(item)
          tag.a(href: item.href,
                class: class_names("active" => item.active?),
                target: item.target, rel: item.rel) do
            safe_join([
              (render(Bali::Icon::Component.new(item.icon, class: "size-4")) if item.icon.present?),
              item.name
            ].compact)
          end
        end

        # Parent's own link inside an accordion or popup. Active only
        # when the parent route matches but no child does — child links
        # own the highlight when active. Returns nil if no href.
        def render_parent_link(in_accordion: false)
          return unless href.present?

          link = tag.a(
            href: href,
            class: class_names({ "menu-item" => in_accordion },
                               "active" => active? && !active_child_items?),
            target: target, rel: rel
          ) { in_accordion ? tag.span(name, class: "grow") : name }

          in_accordion ? link : tag.li(link)
        end

        # Flyout trigger: `<a>` when the parent has its own destination
        # (click navigates, hover/focus opens the popup), `<div>` button
        # otherwise (popup-only). Either way it's keyboard-reachable
        # and wired to the Stimulus controller.
        def render_flyout_trigger
          trigger_class = class_names("menu-item", "active" => active?)

          if href.present?
            tag.a(href: href, tabindex: 0, class: trigger_class,
                  target: target, rel: rel,
                  data: { side_menu_flyout_target: "trigger",
                          action: "keydown->side-menu-flyout#triggerKeydown" }) { render_icon_or_initial }
          else
            tag.div(tabindex: 0, role: "button", class: trigger_class,
                    "aria-label": name,
                    data: { side_menu_flyout_target: "trigger",
                            action: "keydown->side-menu-flyout#triggerKeydown" }) { render_icon_or_initial }
          end
        end

        BADGE_COLOR_CLASSES = {
          primary: "border-primary/20 bg-primary/10 text-primary",
          secondary: "border-secondary/20 bg-secondary/10 text-secondary",
          accent: "border-accent/20 bg-accent/10 text-accent",
          success: "border-success/20 bg-success/10 text-success",
          warning: "border-warning/20 bg-warning/10 text-warning",
          error: "border-error/20 bg-error/10 text-error",
          info: "border-info/20 bg-info/10 text-info"
        }.freeze

        def badge_classes
          class_names(
            "border",
            "rounded-box",
            "px-1.5",
            "text-[12px]",
            BADGE_COLOR_CLASSES[@badge_color]
          )
        end

        # Returns rel attribute for security when opening in new tab
        def rel
          "noopener noreferrer" if @target == "_blank"
        end

        private

        attr_reader :current_path, :match_type

        def parsed_path
          return nil if @href.blank?

          URI.parse(@href).path
        rescue URI::InvalidURIError
          @href
        end
      end
    end
  end
end
