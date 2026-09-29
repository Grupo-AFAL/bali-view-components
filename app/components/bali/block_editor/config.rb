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
      # WATCH OUT with `comments`: turning it on changes the FORM in which the editor
      # persists the content, because comment marks only survive in ProseMirror's JSON.
      # With the default `format: :json` that happens on its own, as soon as somebody
      # comments. If anything outside the editor reads that column, pin the form with
      # `format: :blocks` or `:prosemirror` -- see the FORMATS comment in
      # BlockEditor::Component (#1091).
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

      # A config key passed LOOSE, said out loud.
      #
      # Since v3 these keys travel inside `config:`. Loose they are not a parameter of any
      # of the three components, so they fall into their `**options` and are painted as
      # attributes of the root div: valid HTML, no error, no warning, and the feature stays
      # at its default value. In one host app, AI, export, references and comments had been
      # off since the v3 migration in the three views that mount the DocumentEditor, and
      # nothing gave it away short of looking at the DOM (#1092).
      #
      # It is a `deprecator.warn` and not a raise because these are the v2 keys: the
      # migration goes from "it works until somebody looks at the DOM" to "the log says so
      # on the first render", without taking down anyone's screen.
      #
      # @param options [Hash] what was left over in the component's `**options`
      # @param component [String] the name to name in the warning
      def self.warn_stray_keywords(options, component:)
        stray = options.keys.map(&:to_sym) & ATTRIBUTES
        return if stray.empty?

        Bali.deprecator.warn(
          "#{component}: #{stray.map { |key| "`#{key}:`" }.to_sentence} " \
          "#{stray.one? ? "travels" : "travel"} inside `config:` since v3, so " \
          "#{stray.one? ? "it was" : "they were"} ignored and painted as an HTML attribute " \
          "of the root element. Write " \
          "`config: { #{stray.map { |key| "#{key}: ..." }.join(", ")} }`."
        )
      end

      SIDEBARS = %i[interactive read_only].freeze

      # Whether the threads sidebar carries its own reply box, reaction button and
      # per-comment actions, or is a list you read. Read by CSS through a data
      # attribute the two components put on the sidebar's container.
      #
      # Interactive is the default and, until #1111, was the documented behaviour
      # that the CSS denied: three `display: none !important` rules hid all three
      # controls in every sidebar, while ninety lines further down the same file
      # styled the reply box as if it were visible. A thread whose anchor had been
      # deleted was then unreachable — the floating composer opens from the anchor,
      # and there was no anchor left — so the only way to answer it was gone.
      #
      # `sidebar: :read_only` is that behaviour, kept for a host that wants the
      # panel to be a record rather than a place to write: threads still render,
      # resolved state still shows, and the writing happens at the anchor.
      #
      # Raises on an unknown mode rather than falling back, the way `size_variant`
      # does: a typo that silently means "interactive" is how the sidebar got here.
      #
      # Only a Symbol or a String is symbolized, and the message names the value as
      # it was written. `sidebar: true` — which is how someone reads "turn the panel
      # on" — used to reach `true.to_sym` and die of `NoMethodError` instead: a 500
      # naming neither the option nor the modes, from the one method whose job is to
      # name both (#1113).
      def comments_sidebar
        return :interactive unless comments.is_a?(Hash)

        value = comments.symbolize_keys[:sidebar]
        return :interactive if value.nil?

        mode = value.is_a?(Symbol) || value.is_a?(String) ? value.to_sym : value
        return mode if SIDEBARS.include?(mode)

        raise ArgumentError,
              "comments: { sidebar: #{value.inspect} } is not a sidebar mode. " \
              "Valid: #{SIDEBARS.map(&:inspect).join(', ')}."
      end

      def comments_sidebar_read_only?
        comments_sidebar == :read_only
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
