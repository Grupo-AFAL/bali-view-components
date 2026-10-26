# frozen_string_literal: true

module Bali
  module BpmnEditor
    # Parses and validates the BPMN document (#1489). The contract is a plain
    # Hash (symbol or string keys):
    #
    #   {
    #     version: 12,                    # optimistic concurrency; the server bumps it
    #     orientation: "horizontal",      # or "vertical"
    #     status_label: "Borrador",       # shown as is; the component interprets no states
    #     pool: { x: 0, y: 0, length: nil },  # length: shared lane length, when resized by hand
    #     lanes: [
    #       { id: "l1", name: "Accounts payable", kind: "internal",   # internal | external
    #         order: 1, size: 180,                                    # size: thickness on the stacking axis
    #         assignee: { id: "position:42", label: "...", group: "..." },
    #         appearance: { color: "#DC2626", badge: "Unassigned" }, fields: {} }
    #     ],
    #     nodes: [
    #       { id: "n1", type: "task", lane_id: "l1", name: "Validate invoice",
    #         documentation: "...", x: 120, y: 40, width: 150, height: 64,   # x/y: top-left, pool-relative
    #                                                   # width/height: nil or absent = the type's default («Auto»)
    #         reference: { id: "77", label: "...", url: "/..." },             # sub_process
    #         event_definition: { kind: "timer", expression: "PT1H" },        # events
    #         appearance: { color: "#E9A23B", dimmed: true, badge: "In progress" },  # the app's look
    #         fields: {} }
    #     ],
    #     edges: [ { id: "e1", source: "n1", target: "n2", type: "sequence_flow", label: "Yes",
    #                ports: { source: "auto", target: "left" }, waypoints: [] } ],
    #     annotations: [ { id: "a1", target_id: "n1", number: 1, text: "...", tag: "keep" } ],
    #     stencil: [ { reference: { id: "78", label: "...", url: "/..." } } ],
    #     issues: [ { rule: "R11", element_id: "n9", severity: "error", message: "..." } ]
    #   }
    #
    # Ids are unique across lanes, nodes and edges together: an issue's
    # `element_id` and an annotation's `target_id` name an element without
    # saying which kind it is. The island mints `lane_`, `n_` and `e_` ids.
    #
    # A `url` (a reference's, a stencil item's, a lane assignee's) is followed
    # on a click, so it is a path or http(s); `javascript:` and any other
    # scheme raise.
    #
    # `appearance` is the app's, like `stencil` and `issues`: what a lane or a
    # node looks like (a hex colour, dimmed, a badge of at most BADGE_MAX characters),
    # with no meaning Bali knows. The island draws it — canvas, outputs,
    # comparison — and never sends it back in a save.
    #
    # Node types the island cannot draw are carried through untouched, so a
    # document imported from another tool loses nothing on save.
    #
    # Structural problems (no id, duplicate ids, an unknown orientation, a
    # coordinate that is not a number) raise InvalidError. Dangling references —
    # an edge to a node that is gone, a node in a lane that is gone — do NOT:
    # they are modelling problems the island lists as pending issues (rules R25
    # and R26), and an imported document has to open to be fixed.
    class Data
      class InvalidError < ArgumentError; end

      ORIENTATIONS = %w[horizontal vertical].freeze
      LANE_KINDS = %w[internal external].freeze
      # Mirrors EDGE_TYPES in model/catalog.js (contract_test.rb).
      EDGE_TYPES = %w[sequence_flow message_flow association].freeze
      PORTS = %w[auto top right bottom left].freeze
      SEVERITIES = %w[error warning].freeze
      # Mirror APPEARANCE_COLLECTIONS, APPEARANCE_KEYS and BADGE_MAX in
      # model/appearance.js (contract_test.rb).
      APPEARANCE_COLLECTIONS = %i[lanes nodes].freeze
      APPEARANCE_KEYS = %i[color dimmed badge].freeze
      BADGE_MAX = 24
      HEX_COLOR = /\A#(\h{3}|\h{6})\z/
      # Mirrors NAVIGABLE_SCHEMES in model/urls.js (contract_test.rb).
      NAVIGABLE_SCHEMES = %w[http https].freeze

      # A path or an http(s) URL. What the browser would take as the scheme, as
      # model/urls.js's safeUrl lets the URL parser decide: it drops tabs and
      # newlines anywhere and leading control characters and spaces
      # ("java\tscript:"). Also checked by Bali::BpmnEditorHelper, whose events
      # put a URL in the document without passing through here.
      def self.navigable_url?(url)
        return false unless url.is_a?(String)

        scheme = url.delete("\t\n\r").sub(/\A[\x00-\x20]+/, "")[/\A([a-z][a-z\d+\-.]*):/i, 1]
        scheme.nil? || NAVIGABLE_SCHEMES.include?(scheme.downcase)
      end

      def initialize(payload)
        raise InvalidError, "BPMN data must be a Hash, got #{payload.class}" unless payload.is_a?(Hash)

        @payload = payload.deep_symbolize_keys
        validate!
      end

      def to_h = @payload

      def orientation = (@payload[:orientation] || "horizontal").to_s
      def lanes = Array(@payload[:lanes])
      def nodes = Array(@payload[:nodes])
      def edges = Array(@payload[:edges])
      def issues = Array(@payload[:issues])

      private

      def validate!
        unless ORIENTATIONS.include?(orientation)
          raise InvalidError, "orientation must be one of #{ORIENTATIONS.inspect}, got #{orientation.inspect}"
        end

        integer!(@payload[:version], "version") unless @payload[:version].nil?
        hash!(@payload[:pool], "pool") unless @payload[:pool].nil?
        numeric_keys!(@payload[:pool] || {}, %i[x y length], "pool")
        %i[lanes nodes edges annotations stencil issues].each { |key| array!(key) }

        validate_lanes!
        validate_nodes!
        APPEARANCE_COLLECTIONS.each do |key|
          Array(@payload[key]).each { |element| validate_appearance!(element, key.to_s.singularize) }
        end
        validate_edges!
        validate_issues!
        unique_ids!(lanes + nodes + edges, "element (lanes, nodes and edges share their ids)")
        Array(@payload[:annotations]).each { |annotation| require_id!(annotation, "annotation") }
        Array(@payload[:stencil]).each do |item|
          hash!(item, "stencil item")
          hash!(item[:reference], "stencil item reference")
          navigable_url!(item[:reference], "stencil item #{item[:reference][:id]}: reference")
        end
      end

      def validate_lanes!
        lanes.each do |lane|
          require_id!(lane, "lane")
          kind = (lane[:kind] || "internal").to_s
          unless LANE_KINDS.include?(kind)
            raise InvalidError, "lane #{lane[:id]}: kind must be one of #{LANE_KINDS.inspect}, got #{kind.inspect}"
          end
          numeric_keys!(lane, %i[order size], "lane #{lane[:id]}")
          navigable_url!(lane[:assignee], "lane #{lane[:id]}: assignee")
        end
        unique_ids!(lanes, "lane")
      end

      def validate_nodes!
        nodes.each do |node|
          require_id!(node, "node")
          raise InvalidError, "node #{node[:id]} requires a type" if node[:type].blank?

          numeric_keys!(node, %i[x y width height], "node #{node[:id]}")
          validate_size!(node)
          navigable_url!(node[:reference], "node #{node[:id]}: reference")
        end
        unique_ids!(nodes, "node")
      end

      # Only positive: the limits a person resizes within (MIN_NODE_SIZE and
      # MAX_NODE_SIZE in model/catalog.js) are the island's, since a document
      # may draw an activity outside them — the catalog preview draws each one
      # at its 28 px palette icon size.
      def validate_size!(node)
        %i[width height].each do |key|
          next if node[key].nil? || node[key].to_f.positive?

          raise InvalidError, "node #{node[:id]}: #{key} must be positive, got #{node[key].inspect}"
        end
      end

      def validate_appearance!(element, kind)
        appearance = element[:appearance]
        return if appearance.nil?

        context = "#{kind} #{element[:id]}: appearance"
        hash!(appearance, context)
        unknown = appearance.keys - APPEARANCE_KEYS
        raise InvalidError, "#{context} has unknown keys #{unknown.inspect}; expected #{APPEARANCE_KEYS.inspect}" if unknown.any?
        if appearance.key?(:color) && !appearance[:color].to_s.match?(HEX_COLOR)
          raise InvalidError, "#{context}: color must be a hex colour like \"#E9A23B\", got #{appearance[:color].inspect}"
        end
        if appearance.key?(:dimmed) && ![ true, false ].include?(appearance[:dimmed])
          raise InvalidError, "#{context}: dimmed must be true or false, got #{appearance[:dimmed].inspect}"
        end
        return unless appearance.key?(:badge)
        return if appearance[:badge].is_a?(String) && appearance[:badge].length <= BADGE_MAX

        raise InvalidError, "#{context}: badge must be a string of at most #{BADGE_MAX} characters, got #{appearance[:badge].inspect}"
      end

      def validate_edges!
        edges.each do |edge|
          require_id!(edge, "edge")
          unless edge[:source].present? && edge[:target].present?
            raise InvalidError, "edge #{edge[:id]} requires source and target"
          end
          if edge[:type] && EDGE_TYPES.exclude?(edge[:type].to_s)
            raise InvalidError, "edge #{edge[:id]}: type must be one of #{EDGE_TYPES.inspect}, got #{edge[:type].inspect}"
          end

          hash!(edge[:ports], "edge #{edge[:id]}: ports") unless edge[:ports].nil?
          (edge[:ports] || {}).each do |end_name, side|
            next if PORTS.include?(side.to_s)

            raise InvalidError, "edge #{edge[:id]}: ports.#{end_name} must be one of #{PORTS.inspect}, got #{side.inspect}"
          end
        end
        unique_ids!(edges, "edge")
      end

      def validate_issues!
        issues.each do |issue|
          hash!(issue, "issue")
          raise InvalidError, "issue requires a rule: #{issue.inspect}" if issue[:rule].blank?

          severity = (issue[:severity] || "error").to_s
          next if SEVERITIES.include?(severity)

          raise InvalidError, "issue #{issue[:rule]}: severity must be one of #{SEVERITIES.inspect}, got #{severity.inspect}"
        end
      end

      def navigable_url!(holder, context)
        return unless holder.is_a?(Hash) && holder[:url].present?
        return if self.class.navigable_url?(holder[:url])

        raise InvalidError, "#{context}: url must be a path or #{NAVIGABLE_SCHEMES.join('/')}, got #{holder[:url].inspect}"
      end

      def hash!(value, context)
        raise InvalidError, "#{context} must be a Hash, got #{value.inspect}" unless value.is_a?(Hash)
      end

      def array!(key)
        value = @payload[key]
        return if value.nil? || value.is_a?(Array)

        raise InvalidError, "#{key} must be an Array, got #{value.class}"
      end

      def require_id!(element, kind)
        raise InvalidError, "#{kind} must be a Hash, got #{element.inspect}" unless element.is_a?(Hash)
        raise InvalidError, "#{kind} requires an id: #{element.inspect}" if element[:id].blank?
      end

      def unique_ids!(elements, kind)
        duplicated = elements.map { |e| e[:id].to_s }.tally.select { |_, count| count > 1 }.keys
        return if duplicated.empty?

        raise InvalidError, "duplicate #{kind} ids: #{duplicated.inspect}"
      end

      def numeric_keys!(hash, keys, context)
        keys.each do |key|
          value = hash[key]
          next if value.nil? || value.is_a?(Numeric)
          next if value.is_a?(String) && value.match?(/\A-?\d+(\.\d+)?\z/)

          raise InvalidError, "#{context}: #{key} must be a number, got #{value.inspect}"
        end
      end

      def integer!(value, context)
        Integer(value)
      rescue ArgumentError, TypeError
        raise InvalidError, "#{context} must be an integer, got #{value.inspect}"
      end
    end
  end
end
