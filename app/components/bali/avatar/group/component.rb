# frozen_string_literal: true

module Bali
  module Avatar
    module Group
      class Component < ApplicationViewComponent
        renders_many :avatars, Bali::Avatar::Component
        renders_one :counter

        SPACINGS = {
          tight: '-space-x-4',
          normal: '-space-x-6',
          loose: '-space-x-8'
        }.freeze

        def initialize(spacing: :normal, **options)
          @spacing = spacing&.to_sym
          @options = options
        end

        def group_classes
          class_names(
            'avatar-group',
            SPACINGS[@spacing] || SPACINGS[:normal],
            @options[:class]
          )
        end

        def counter_classes
          class_names(
            'avatar',
            'avatar-placeholder'
          )
        end

        def counter_inner_classes
          class_names(
            'bg-neutral',
            'text-neutral-content',
            'w-12'
          )
        end
      end
    end
  end
end
