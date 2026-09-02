# frozen_string_literal: true

module Bali
  # Reading the editor's stored JSON from Ruby.
  #
  # The editor persists its content in one of two shapes, and until #1091 which one you got
  # was not the host's decision: turning `comments:` on made the FIRST USER WHO LEFT A
  # COMMENT rewrite the column into the other one, because BlockNote strips comment marks
  # from `editor.document` and only the ProseMirror JSON preserves them. With auto-save that
  # happened without anybody asking.
  #
  #   editor.document (`:blocks`)          _tiptapEditor.getJSON() (`:prosemirror`)
  #   ───────────────────────────          ────────────────────────────────────────
  #   Array of blocks                      { "type" => "doc", "content" => [...] }
  #   no wrappers                          blockGroup / blockContainer
  #   node properties under "props"        under "attrs"
  #   { "type" => "tableContent", ... }    table → tableRow → tableCell
  #
  # Everything server-side that reads that column — extracting entity references, indexing
  # text for search, diffing versions, publishing snapshots, exporting — has to know which
  # shape it was handed. `format:` now lets a host pin one (see BlockEditor::Component), and
  # this answers the question for content that is already stored, including the rows written
  # before the pin.
  module BlockEditor
    # The shape of a stored JSON document: `:blocks`, `:prosemirror`, or nil for anything
    # that is neither (nil, an empty string, a column that never held editor content).
    #
    # Deliberately structural rather than a stored marker: the shapes are told apart by
    # their root, so this answers for every row an app already has, whatever wrote it.
    #
    # @param content [String, Array, Hash, nil] the column, parsed or still as JSON text
    # @return [Symbol, nil]
    def self.content_format(content)
      content = parse(content) if content.is_a?(String)

      return :blocks if content.is_a?(Array)
      # Las dos grafías de la llave: un Hash puede venir de `JSON.parse` o de un literal.
      return :prosemirror if content.is_a?(Hash) && (content["type"] || content[:type]).to_s == "doc"

      nil
    end

    def self.parse(content)
      JSON.parse(content)
    rescue JSON::ParserError
      nil
    end
    private_class_method :parse
  end
end
