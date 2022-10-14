# frozen_string_literal: true

module Bali
  module SideMenu
    module Item
      class Component < ApplicationViewComponent
        renders_many :items, ->(href:, name: nil, icon: nil, authorized: true, **options) do
          Item::Component.new(
            name: name,
            href: href,
            icon: icon,
            authorized: authorized,
            current_path: @current_path,
            **options
          )
        end

        attr_reader :href, :current_path, :match_type

        def initialize(href:, current_path:, name: nil, icon: nil, authorized: true, **options)
          @name = name
          @href = href
          @icon = icon
          @authorized = authorized
          @current_path = current_path

          @active = options.delete(:active)
          @match_type = options.delete(:match) || :exact
          @options = options
        end

        def before_render
          super

          @options = prepend_class_name(@options, 'is-active') if active?
        end

        def render?
          @authorized
        end

        def uri
          URI(@href)
        end

        def disabled?
          @href.blank?
        end

        def active?
          return @active unless @active.nil?

          active_path?(uri.path, current_path, match: match_type) || active_child_items?
        end

        def active_child_items?
          items.reject(&:disabled?).any?(&:active?)
        end
      end
    end
  end
end
