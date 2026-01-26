# frozen_string_literal: true

module Bali
  module Icon
    # Provides backwards-compatible icon lookup and listing.
    #
    # Note: The Component class now uses a resolution pipeline that tries
    # Lucide icons first. This class is maintained for:
    # - Legacy code that calls Options.find() directly
    # - Listing all available icons in previews
    # - Custom icon extension via Bali.custom_icons
    #
    # rubocop:disable Metrics/ClassLength
    class Options
      extend DefaultIcons

      class IconNotAvailable < StandardError; end

      class << self
        # Returns all available icon names (for previews and documentation)
        #
        # @return [Hash<String, String>] icon name => SVG content
        def icons
          @icons ||= build_icons_hash
        end

        # Returns just the icon names
        #
        # @return [Array<String>]
        def icon_names
          icons.keys
        end

        # Find an icon by name (legacy method, maintained for backwards compatibility)
        # Prefer using Bali::Icon::Component.new(name) for rendering.
        #
        # @param name [String, Symbol] the icon name
        # @return [String] SVG markup
        # @raise [IconNotAvailable] if icon not found
        def find(name)
          name_str = name.to_s
          raise IconNotAvailable, "Icon: '#{name}' is not available" unless icons.key?(name_str)

          icons[name_str].html_safe
        end

        # Check if an icon exists
        #
        # @param name [String, Symbol] the icon name
        # @return [Boolean]
        def exists?(name)
          icons.key?(name.to_s)
        end

        # Clear cached icons (useful for testing or when custom icons change)
        def reset!
          @icons = nil
        end

        private

        # Builds the complete icons hash from all sources
        # This includes legacy DefaultIcons for backwards compatibility
        def build_icons_hash
          legacy_icons.merge!(Bali.custom_icons)
        end

        # Legacy icons from DefaultIcons module
        # These are maintained for backwards compatibility
        # rubocop:disable Metrics/MethodLength
        def legacy_icons
          {
            'address-book' => ADDRESS_BOOK,
            'alert' => ALERT,
            'alert-alt' => ALERT_ALT,
            'align-left' => ALIGN_LEFT,
            'align-center' => ALIGN_CENTER,
            'align-right' => ALIGN_RIGHT,
            'angle-double-down' => ANGLE_DOUBLE_DOWN,
            'angle-double-up' => ANGLE_DOUBLE_UP,
            'american-express' => AMERICAN_EXPRESS,
            'arrow-left' => ARROW_LEFT,
            'arrow-right' => ARROW_RIGHT,
            'arrow-right-up' => ARROW_RIGHT_UP,
            'arrow-back' => ARROW_BACK,
            'arrow-forward' => ARROW_FORWARD,
            'attachment' => ATTACHMENT,
            'baby' => BABY,
            'badge-percent' => BADGE_PERCENT,
            'band-aid' => BAND_AID,
            'bed' => BED,
            'bell' => BELL,
            'bold' => BOLD,
            'bookmark' => BOOKMARK,
            'books' => BOOKS,
            'box-archive' => BOX_ARCHIVE,
            'business' => BUSINESS,
            'calendar-alt' => CALENDAR_ALT,
            'camera' => CAMERA,
            'capsules' => CAPSULES,
            'chair' => CHAIR,
            'chart-line' => CHART_LINE,
            'check' => CHECK,
            'check-circle' => CHECK_CIRCLE,
            'checklist' => CHECKLIST,
            'chevron-doble-down' => CHEVRON_DOBLE_DOWN,
            'chevron-doble-up' => CHEVRON_DOBLE_UP,
            'chevron-down' => CHEVRON_DOWN,
            'chevron-left' => CHEVRON_LEFT,
            'chevron-right' => CHEVRON_RIGHT,
            'child' => CHILD,
            'clock' => CLOCK,
            'cloud-upload-alt' => CLOUD_UPLOAD_ALT,
            'cog' => COG,
            'coins' => COINS,
            'comment' => COMMENT,
            'comment-dollar' => COMMENT_DOLLAR,
            'copy' => COPY,
            'credit-card' => CREDIT_CARD,
            'credit-card-alt' => CREDIT_CARD_ALT,
            'cutlery' => CUTLERY,
            'cutlery-alt' => CUTLERY_ALT,
            'dashboard' => DASHBOARD,
            'diagnose' => DIAGNOSE,
            'door-open' => DOOR_OPEN,
            'download' => DOWNLOAD,
            'edit' => EDIT,
            'edit-alt' => EDIT_ALT,
            'ellipsis-h' => ELLIPSIS_H,
            'exclamation-circle' => EXCLAMATION_CIRCLE,
            'expand' => EXPAND,
            'external-link-alt' => EXTERNAL_LINK_ALT,
            'facebook-square' => FACEBOOK_SQUARE,
            'facebook' => FACEBOOK,
            'file-export' => FILE_EXPORT,
            'face-profile' => FACE_PROFILE,
            'file-certificate' => FILE_CERTIFICATE,
            'file-signature' => FILE_SIGNATURE,
            'filter' => FILTER,
            'filter-alt' => FILTER_ALT,
            'fire-alt' => FIRE_ALT,
            'grid' => GRID,
            'day' => DAY,
            'month' => MONTH,
            'ticket' => TICKET,
            'week' => WEEK,
            'gift' => GIFT,
            'github' => GITHUB,
            'grin-wink' => GRIN_WINK,
            'handle' => HANDLE,
            'home' => HOME,
            'image' => IMAGE,
            'images' => IMAGES,
            'infinity' => INFINITY,
            'info-circle' => INFO_CIRCLE,
            'info-circle-alt' => INFO_CIRCLE_ALT,
            'instagram-square' => INSTAGRAM_SQUARE,
            'instagram' => INSTAGRAM,
            'indent' => INDENT,
            'italic' => ITALIC,
            'laptop-code' => LAPTOP_CODE,
            'link' => LINK,
            'link-alt' => LINK_ALT,
            'linkedin' => LINKEDIN,
            'lightbulb' => LIGHTBULB,
            'list' => LIST,
            'long-arrow-alt-left' => LONG_ARROW_ALT_LEFT,
            'map-marker-alt' => MAP_MARKER_ALT,
            'map-marked-alt' => MAP_MARKED_ALT,
            'magic-wand' => MAGIC_WAND,
            'mail' => MAIL,
            'mastercard' => MASTERCARD,
            'mexico-flag' => MEXICO_FLAG,
            'minus' => MINUS,
            'money-bill-wave' => MONEY_BILL_WAVE,
            'more' => MORE,
            'mute' => MUTE,
            'nested-arrow' => NESTED_ARROW,
            'notification' => NOTIFICATION,
            'outdent' => OUTDENT,
            'outlook' => OUTLOOK,
            'oxxo' => OXXO,
            'paypal' => PAYPAL,
            'pen' => PEN,
            'pin' => PIN,
            'pinterest' => PINTEREST,
            'phone' => PHONE,
            'phone-plus' => PHONE_PLUS,
            'plus' => PLUS,
            'plus-circle' => PLUS_CIRCLE,
            'poo' => POO,
            'print' => PRINT,
            'project-diagram' => PROJECT_DIAGRAM,
            'question_circle' => QUESTION_CIRCLE,
            'receipt' => RECEIPT,
            'recipe-book' => RECIPE_BOOK,
            'report' => REPORT,
            'running' => RUNNING,
            'search' => SEARCH,
            'search-minus' => SEARCH_MINUS,
            'search-plus' => SEARCH_PLUS,
            'shapes' => SHAPES,
            'snowflake' => SNOWFLAKE,
            'success' => SUCCESS,
            'shopping-cart' => SHOPPING_CART,
            'sound' => SOUND,
            'space-station-moon-alt' => SPACE_STATION_MOON_ALT,
            'sparkles' => SPARKLES,
            'square-phone' => SQUARE_PHONE,
            'star' => STAR,
            'sticky-note' => STICKY_NOTE,
            'store' => STORE,
            'strikethrough' => STRIKETHROUGH,
            'table' => TABLE,
            'tags' => TAGS,
            'times-circle' => TIMES_CIRCLE,
            'times' => TIMES,
            'toilet' => TOILET,
            'trash' => TRASH,
            'trash-alt' => TRASH_ALT,
            'trophy-alt' => TROPHY_ALT,
            'truck' => TRUCK,
            'truck-loading' => TRUCK_LOADING,
            'twitter' => TWITTER,
            'underline' => UNDERLINE,
            'upload' => UPLOAD,
            'us-flag' => US_FLAG,
            'user' => USER,
            'users' => USERS,
            'user-plus' => USER_PLUS,
            'utensils-alt' => UTENSILS_ALT,
            'visa' => VISA,
            'wallet' => WALLET,
            'wallet-alt' => WALLET_ALT,
            'weight' => WEIGHT,
            'whatsapp' => WHATSAPP,
            'whatsapp-square' => WHATSAPP_SQUARE,
            'youtube' => YOUTUBE
          }
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
