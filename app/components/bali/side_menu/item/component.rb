# frozen_string_literal: true

module Bali
  module SideMenu
    module Item
      class Component < ApplicationViewComponent
        MATCH_TYPES = %i[exact partial starts_with crud].freeze
        GROUP_BEHAVIORS = %i[expandable dropdown].freeze

        renders_many :items,
                     lambda { |href: nil, name: nil, icon: nil,
                               authorized: true, disabled: false, **options|
                       Item::Component.new(
                         name: name,
                         href: href,
                         icon: icon,
                         authorized: authorized,
                         disabled: disabled,
                         current_path: @current_path,
                         group_behavior: @group_behavior,
                         **options
                       )
                     }

        attr_reader :name, :icon, :badge, :href

        def initialize(current_path:, href: nil, name: nil, icon: nil, authorized: true,
                       group_behavior: :expandable, disabled: false, **options)
          @name = name
          @href = href
          @icon = icon
          @authorized = authorized
          @current_path = current_path
          @group_behavior = GROUP_BEHAVIORS.include?(group_behavior) ? group_behavior : :expandable
          @disabled = disabled
          @active = options.delete(:active)
          @match_type = MATCH_TYPES.include?(options[:match]) ? options.delete(:match) : :exact
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
            active_child_items?
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

        # Unique ID for collapse checkbox
        def collapse_id
          @collapse_id ||= "side-menu-item-#{object_id}"
        end

        def menu_item_classes
          class_names(
            'menu-item',
            'group',
            { 'active' => active? && !subitems? },
            @link_class
          )
        end

        def collapse_title_classes
          class_names(
            'collapse-title',
            'px-2.5',
            'py-1.5',
            { 'active' => active? }
          )
        end

        # Translated aria-label for collapse toggle
        def toggle_label
          I18n.t('bali.side_menu.toggle_item', name: name, default: "Toggle #{name}")
        end

        def badge_classes
          class_names(
            'border',
            'rounded-box',
            'px-1.5',
            'text-[12px]',
            "border-#{@badge_color}/20",
            "bg-#{@badge_color}/10",
            "text-#{@badge_color}"
          )
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
