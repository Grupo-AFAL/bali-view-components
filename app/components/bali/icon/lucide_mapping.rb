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
    class LucideMapping
      # This map is consulted BEFORE the name is tried as a Lucide icon, so a
      # key that is itself a current Lucide name and points at a different
      # glyph shadows the real icon — the honest spelling becomes unreachable,
      # with no error and no warning. Do not add entries like that; the
      # shadowing test in lucide_mapping_test.rb freezes the set so it can
      # only shrink. `trash`, `cog`, `expand`, `indent` and `outdent` were
      # removed for exactly that (#902) and now draw their real Lucide glyph.
      #
      # Three shadowing entries stay, deliberately:
      #
      # * `check-circle` => `circle-check`: Lucide renamed check-circle to
      #   circle-check in 2023, and the `check-circle` file lucide-rails still
      #   ships is the legacy glyph (the check overflowing the circle).
      #   Pointing at the modern canonical drawing is the correct behaviour,
      #   and the entry keeps working the day lucide-rails drops the file.
      # * `edit` => `pencil`: `edit` in Lucide is a deprecated alias whose
      #   real rename was `square-pen` — NOT `pencil`. The target is the
      #   v1/v2 visual continuity, chosen on purpose; dropping the entry
      #   would swap every measured call site from a pencil to a
      #   pencil-in-square without gaining a current name.
      # * `plus-circle` => `circle-plus`: same rename story as check-circle,
      #   but the legacy file draws the same thing — the entry only protects
      #   against the alias file being dropped.
      #
      # Identity entries ("check" => "check", …) are dead weight — the
      # direct-Lucide step resolves them identically — and the same test
      # keeps them out.
      #
      # Mapping from Bali icon names to Lucide icon names
      MAPPING = {
        # Alerts & Status
        "alert" => "triangle-alert",
        "alert-alt" => "circle-alert",
        "exclamation-circle" => "circle-alert",
        "info-circle" => "info",
        "info-circle-alt" => "info",
        "success" => "circle-check",
        "check-circle" => "circle-check",
        "times" => "x",
        "times-circle" => "circle-x",
        "question_circle" => "circle-help",

        # Arrows & Navigation
        "arrow-right-up" => "arrow-up-right",
        "arrow-back" => "chevron-left",
        "arrow-forward" => "chevron-right",
        "chevron-doble-down" => "chevrons-down",
        "chevron-doble-up" => "chevrons-up",
        "angle-double-down" => "chevrons-down",
        "angle-double-up" => "chevrons-up",
        "long-arrow-alt-left" => "arrow-left",
        "external-link-alt" => "external-link",

        # Files & Documents
        "attachment" => "paperclip",
        "file-export" => "file-output",
        "file-certificate" => "file-badge",

        # Actions
        "edit" => "pencil",
        "edit-alt" => "pen",
        "trash-alt" => "trash",
        "plus-circle" => "circle-plus",
        "search-minus" => "zoom-out",
        "search-plus" => "zoom-in",
        "filter-alt" => "sliders-horizontal",
        "cloud-upload-alt" => "cloud-upload",
        "print" => "printer",

        # UI Elements
        "ellipsis-h" => "ellipsis",
        "more" => "more-horizontal",
        "dashboard" => "layout-dashboard",
        "notification" => "bell-ring",
        "handle" => "grip-vertical",
        "link-alt" => "link-2",

        # Communication
        "comment" => "message-circle",
        "phone-plus" => "phone-call",
        "square-phone" => "phone",

        # Users
        "address-book" => "contact",
        "face-profile" => "user",

        # Business & Finance
        "business" => "building-2",
        "wallet-alt" => "wallet-cards",
        "credit-card-alt" => "credit-card",

        # Calendar & Time
        "calendar-alt" => "calendar",

        # Charts
        "project-diagram" => "workflow",

        # Objects
        "truck-loading" => "truck",
        "trophy-alt" => "trophy",
        "books" => "library",
        "box-archive" => "archive",
        "checklist" => "list-checks",
        "magic-wand" => "wand-2",
        "fire-alt" => "flame",

        # People & Body
        "child" => "baby",
        "running" => "person-standing",

        # Health & Medical
        "band-aid" => "bandage",
        "capsules" => "pill",

        # Places & Travel
        "chair" => "armchair",
        "map-marker-alt" => "map-pin",
        "map-marked-alt" => "map",

        # Food & Drink
        "cutlery" => "utensils",
        "cutlery-alt" => "utensils-crossed",
        "utensils-alt" => "utensils",

        # Misc
        "laptop-code" => "laptop",
        "sound" => "volume-2",
        "mute" => "volume-x",
        "report" => "file-text",
        "grin-wink" => "smile",
        "poo" => "frown"
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
  end
end
