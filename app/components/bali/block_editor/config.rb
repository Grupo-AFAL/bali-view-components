# frozen_string_literal: true

module Bali
  module BlockEditor
    # The editor feature set that BlockEditor, DocumentEditor and DocumentPage share.
    #
    # Before v3 each of the three re-declared the same keyword arguments purely to
    # forward them: DocumentEditor carried twelve it never read, DocumentPage three.
    # Adding one editor feature meant editing three signatures, three attr_reader
    # lists and three render calls, and a feature wired into two of the three was
    # indistinguishable from one deliberately left out of the third -- which is how
    # DocumentPage ended up unable to render mentions at all.
    #
    # Config makes that set a single value that travels whole. The wrappers now
    # forward one object instead of mirroring an API they do not own.
    class Config
      # Only features that are meaningful in all three contexts belong here.
      # Deliberately absent: `editable`, `initial_content`, `input_name`, `format`,
      # `preset`, `placeholder`, `theme`, `table_of_contents*`, `show_export_buttons`
      # and `comments_container_id` -- each wrapper decides those for itself, and a
      # shared value would be a wrapper silently overriding its own layout.
      ATTRIBUTES = %i[
        ai_url
        mentions_url
        mentions
        references_url
        references_resolve_url
        references_config
        comments
        export
        export_filename
        multi_column
        upload_url
        syntax_highlighting
      ].freeze

      attr_reader(*ATTRIBUTES)

      # Accepts what a host is likely to pass: nothing, a Config, or a plain Hash.
      # A Hash is the ergonomic form (`config: { ai_url: ... }`) and costs nothing
      # to support, so requiring the constructor would be ceremony for its own sake.
      def self.wrap(value)
        case value
        when nil then new
        when self then value
        when Hash then new(**value.symbolize_keys)
        else
          raise ArgumentError,
                "Bali::BlockEditor::Config.wrap expects nil, a Config or a Hash, got #{value.class}"
        end
      end

      # `upload_url` defaults to :auto rather than nil, matching
      # BlockEditor::Component: nil is a meaningful value there (uploads off), so
      # nil-as-unset would make "no uploads" impossible to express.
      def initialize(
        ai_url: nil,
        mentions_url: nil,
        mentions: nil,
        references_url: nil,
        references_resolve_url: nil,
        references_config: nil,
        comments: false,
        export: false,
        export_filename: nil,
        multi_column: false,
        upload_url: :auto,
        syntax_highlighting: nil
      )
        @ai_url = ai_url
        @mentions_url = mentions_url
        @mentions = mentions
        @references_url = references_url
        @references_resolve_url = references_resolve_url
        @references_config = references_config
        @comments = comments
        @export = export
        @export_filename = export_filename
        @multi_column = multi_column
        @upload_url = upload_url
        @syntax_highlighting = syntax_highlighting
      end

      def to_h
        ATTRIBUTES.index_with { |name| public_send(name) }
      end

      # Returns a new Config; never mutates. A Config handed to two components has
      # to survive the first one -- the FormBuilder option bug (#744) was exactly
      # this shape, one caller's hash accumulating another caller's state.
      #
      # Takes a Hash and merges only the keys it actually contains. It deliberately
      # does NOT take a Config: every attribute of a Config is populated, so merging
      # one would overwrite all twelve with defaults rather than the two the caller
      # meant -- `comments: false` from an unrelated default would silently turn
      # comments off.
      def merge(overrides)
        return self if overrides.blank?

        unless overrides.is_a?(Hash)
          raise ArgumentError, "Bali::BlockEditor::Config#merge expects a Hash, got #{overrides.class}"
        end

        self.class.new(**to_h.merge(overrides.symbolize_keys.slice(*ATTRIBUTES)))
      end

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end
      alias eql? ==

      def hash
        to_h.hash
      end
    end
  end
end
