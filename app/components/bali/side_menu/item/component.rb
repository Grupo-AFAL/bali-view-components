# frozen_string_literal: true

module Bali
  module SideMenu
    module Item
      class Component < ApplicationViewComponent
        MATCH_TYPES = %i[exact partial starts_with crud].freeze

        renders_many :items, ->(href: nil, name: nil, icon: nil, authorized: true, **options) do
          Item::Component.new(
            name: name,
            href: href,
            icon: icon,
            authorized: authorized,
            current_path: @current_path,
            **options
          )
        end

        def initialize(current_path:, href: nil, name: nil, icon: nil, authorized: true, **options)
          @name = name
          @href = href
          @icon = icon
          @authorized = authorized
          @current_path = current_path
          @active = options.delete(:active)
          @match_type = MATCH_TYPES.include?(options[:match]) ? options.delete(:match) : :exact
          @link_class = options.delete(:class)
          @options = prepend_data_attribute(options, :side_menu_target, 'link')
        end

        def before_render
          super
          @computed_classes = compute_item_classes
          @computed_options = compute_link_options
        end

        def render?
          @authorized
        end

        def subitems?
          items.present?
        end

        def disabled?
          @href.blank?
        end

        def active?
          return @active unless @active.nil?

          (!disabled? && active_path?(parsed_path, @current_path, match: @match_type)) ||
            active_child_items?
        end

        def active_child_items?
          items.reject(&:disabled?).any?(&:active?)
        end

        def item_classes
          @computed_classes
        end

        def link_options
          @computed_options
        end

        private

        attr_reader :href, :current_path, :match_type

        def parsed_path
          return nil if @href.blank?

          URI.parse(@href).path
        rescue URI::InvalidURIError
          @href
        end

        def compute_item_classes
          class_names(
            @link_class,
            'side-menu-component--item-component',
            'is-expanded'
          )
        end

        def compute_link_options
          opts = @options.dup
          opts[:class] = class_names(opts[:class], 'active') if active?
          opts[:data] ||= {}
          opts[:data][:action] = 'click->reveal#toggle' if subitems?
          opts
        end
      end
    end
  end
end
