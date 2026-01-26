# frozen_string_literal: true

module Bali
  module Icon
    # Maps Bali icon names to Lucide icon names for backwards compatibility.
    # This allows existing code using old icon names to continue working
    # while we transition to Lucide's naming conventions.
    #
    # Usage:
    #   LucideMapping.find('edit') # => 'pencil'
    #   LucideMapping.find('unknown') # => nil
    #
    # rubocop:disable Metrics/ClassLength
    class LucideMapping
      # Mapping from Bali icon names to Lucide icon names
      MAPPING = {
        # Alerts & Status
        'alert' => 'triangle-alert',
        'alert-alt' => 'circle-alert',
        'exclamation-circle' => 'circle-alert',
        'info-circle' => 'info',
        'info-circle-alt' => 'info',
        'success' => 'circle-check',
        'check' => 'check',
        'check-circle' => 'circle-check',
        'times' => 'x',
        'times-circle' => 'circle-x',
        'question_circle' => 'circle-help',

        # Arrows & Navigation
        'arrow-left' => 'arrow-left',
        'arrow-right' => 'arrow-right',
        'arrow-right-up' => 'arrow-up-right',
        'arrow-back' => 'chevron-left',
        'arrow-forward' => 'chevron-right',
        'chevron-down' => 'chevron-down',
        'chevron-left' => 'chevron-left',
        'chevron-right' => 'chevron-right',
        'chevron-doble-down' => 'chevrons-down',
        'chevron-doble-up' => 'chevrons-up',
        'angle-double-down' => 'chevrons-down',
        'angle-double-up' => 'chevrons-up',
        'long-arrow-alt-left' => 'arrow-left',
        'external-link-alt' => 'external-link',
        'expand' => 'maximize',

        # Text Formatting
        'align-left' => 'align-left',
        'align-center' => 'align-center',
        'align-right' => 'align-right',
        'bold' => 'bold',
        'italic' => 'italic',
        'underline' => 'underline',
        'strikethrough' => 'strikethrough',
        'indent' => 'indent-increase',
        'outdent' => 'indent-decrease',

        # Files & Documents
        'attachment' => 'paperclip',
        'file-export' => 'file-output',
        'file-certificate' => 'file-badge',
        'file-signature' => 'file-pen',
        'copy' => 'copy',
        'sticky-note' => 'sticky-note',

        # Actions
        'edit' => 'pencil',
        'edit-alt' => 'pen',
        'pen' => 'pen',
        'trash' => 'trash-2',
        'trash-alt' => 'trash',
        'plus' => 'plus',
        'plus-circle' => 'circle-plus',
        'minus' => 'minus',
        'search' => 'search',
        'search-minus' => 'zoom-out',
        'search-plus' => 'zoom-in',
        'filter' => 'filter',
        'filter-alt' => 'sliders-horizontal',
        'download' => 'download',
        'upload' => 'upload',
        'cloud-upload-alt' => 'cloud-upload',
        'print' => 'printer',

        # UI Elements
        'cog' => 'settings',
        'ellipsis-h' => 'ellipsis',
        'more' => 'more-horizontal',
        'grid' => 'grid-2x2',
        'list' => 'list',
        'table' => 'table',
        'dashboard' => 'layout-dashboard',
        'home' => 'home',
        'door-open' => 'door-open',
        'bookmark' => 'bookmark',
        'star' => 'star',
        'bell' => 'bell',
        'notification' => 'bell-ring',
        'handle' => 'grip-vertical',
        'link' => 'link',
        'link-alt' => 'link-2',

        # Media
        'image' => 'image',
        'images' => 'images',
        'camera' => 'camera',

        # Communication
        'mail' => 'mail',
        'comment' => 'message-circle',
        'phone' => 'phone',
        'phone-plus' => 'phone-call',
        'square-phone' => 'phone',

        # Users
        'user' => 'user',
        'users' => 'users',
        'user-plus' => 'user-plus',
        'address-book' => 'contact',
        'face-profile' => 'user',

        # Business & Finance
        'business' => 'building-2',
        'store' => 'store',
        'wallet' => 'wallet',
        'wallet-alt' => 'wallet-cards',
        'credit-card' => 'credit-card',
        'credit-card-alt' => 'credit-card',
        'coins' => 'coins',
        'receipt' => 'receipt',
        'shopping-cart' => 'shopping-cart',
        'tags' => 'tags',
        'badge-percent' => 'badge-percent',

        # Calendar & Time
        'calendar-alt' => 'calendar',
        'clock' => 'clock',

        # Charts
        'chart-line' => 'chart-line',
        'project-diagram' => 'workflow',

        # Objects
        'lightbulb' => 'lightbulb',
        'gift' => 'gift',
        'truck' => 'truck',
        'truck-loading' => 'truck',
        'trophy-alt' => 'trophy',
        'weight' => 'weight',
        'books' => 'library',
        'box-archive' => 'archive',
        'checklist' => 'list-checks',
        'shapes' => 'shapes',
        'infinity' => 'infinity',
        'magic-wand' => 'wand-2',
        'sparkles' => 'sparkles',
        'fire-alt' => 'flame',
        'snowflake' => 'snowflake',

        # People & Body
        'baby' => 'baby',
        'child' => 'baby',
        'running' => 'person-standing',

        # Health & Medical
        'band-aid' => 'bandage',
        'capsules' => 'pill',

        # Places & Travel
        'bed' => 'bed',
        'chair' => 'armchair',
        'map-marker-alt' => 'map-pin',
        'map-marked-alt' => 'map',
        'pin' => 'pin',
        'toilet' => 'toilet',

        # Food & Drink
        'cutlery' => 'utensils',
        'cutlery-alt' => 'utensils-crossed',
        'utensils-alt' => 'utensils',

        # Misc
        'laptop-code' => 'laptop',
        'sound' => 'volume-2',
        'mute' => 'volume-x',
        'report' => 'file-text',
        'grin-wink' => 'smile',
        'poo' => 'frown'
      }.freeze
      # Find the Lucide icon name for a given Bali icon name
      #
      # @param name [String, Symbol] the Bali icon name
      # @return [String, nil] the Lucide icon name, or nil if not mapped
      def self.find(name)
        MAPPING[name.to_s]
      end

      # Check if a Bali icon name has a Lucide mapping
      #
      # @param name [String, Symbol] the Bali icon name
      # @return [Boolean]
      def self.mapped?(name)
        MAPPING.key?(name.to_s)
      end

      # Get all mapped Bali icon names
      #
      # @return [Array<String>]
      def self.bali_names
        MAPPING.keys
      end

      # Get all Lucide icon names used in mappings
      #
      # @return [Array<String>]
      def self.lucide_names
        MAPPING.values.uniq
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
