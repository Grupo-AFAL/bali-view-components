# frozen_string_literal: true

module Bali
  module StatCard
    class Component < ApplicationViewComponent
      COLORS = {
        primary: { bg: 'bg-primary/10', text: 'text-primary' },
        secondary: { bg: 'bg-secondary/10', text: 'text-secondary' },
        accent: { bg: 'bg-accent/10', text: 'text-accent' },
        success: { bg: 'bg-success/10', text: 'text-success' },
        warning: { bg: 'bg-warning/10', text: 'text-warning' },
        error: { bg: 'bg-error/10', text: 'text-error' },
        info: { bg: 'bg-info/10', text: 'text-info' }
      }.freeze

      renders_one :footer

      def initialize(title:, value:, icon_name:, color: :primary, **options)
        @title = title
        @value = value
        @icon_name = icon_name
        @color = (color || :primary).to_sym
        @options = options
      end

      def card_options
        @options.merge(style: :bordered)
      end

      def icon_container_classes
        class_names('p-3 rounded-full', icon_bg_class)
      end

      def icon_bg_class
        COLORS.dig(@color, :bg) || COLORS[:primary][:bg]
      end

      def icon_text_class
        COLORS.dig(@color, :text) || COLORS[:primary][:text]
      end

      private

      attr_reader :title, :value, :icon_name, :color, :options
    end
  end
end
