# frozen_string_literal: true

require "json"

module Bali
  module BlockNote
    # Shared BlockNote JSON text extraction. Single source of truth for
    # converting BlockNote block structures into plain text.
    #
    # Pure Ruby on purpose: no ActiveSupport core extensions and no database,
    # so hosts can lean on it from models, jobs, or scripts alike. Diffing
    # (Bali::BlockNote::Diff) and chunking (Bali::BlockNote::Chunker) share
    # this extractor — anything user-visible must contribute here, or the
    # diff misses edits whose text survives (e.g. a plain word swapped for an
    # entityReference chip of the same name).
    module Text
      module_function

      # Extracts plain text from a single BlockNote block (heading, paragraph,
      # etc.). Covers inline `text` and `entityReference` nodes, table blocks
      # (both `tableRow` and `tableContent` shapes), and recursively descends
      # into nested children.
      def extract_text(block)
        inline = inline_text(block["content"])
        children = Array(block["children"])
                     .map { |b| extract_text(b) }
                     .join(" ")
        cells = table_cell_text(block)
        [ inline, children, *cells ].reject { |part| part.strip.empty? }.join(" ")
      end

      # Inline content can be an Array of inline nodes (paragraph, heading) or
      # a Hash wrapper such as `{ "type" => "tableContent", "rows" => [...] }`
      # for the `table` block shape. Hash wrappers are handled in
      # `table_cell_text`, so this only walks Array shapes here.
      def inline_text(inline)
        return "" unless inline.is_a?(Array)

        inline.filter_map { |node| inline_node_text(node) }.join
      end

      INLINE_TEXT_EXTRACTORS = {
        "text"            => ->(node) { node["text"] },
        "entityReference" => ->(node) { node.dig("props", "entityName") }
      }.freeze

      def inline_node_text(node)
        return nil unless node.is_a?(Hash)

        extractor = INLINE_TEXT_EXTRACTORS[node["type"]]
        extractor&.call(node)
      end

      # Pulls plain text out of every cell in a table block, supporting both:
      #   - Legacy `tableRow` shape: block["cells"] = [[ inline_node, ... ], ...]
      #   - Current `table` block:   block["content"] = { type: "tableContent",
      #       rows: [{ cells: [{ content: [...] }] }] }
      def table_cell_text(block)
        case block["type"]
        when "tableRow"
          Array(block["cells"]).flat_map { |row| Array(row).filter_map { |c| inline_node_text(c) } }
        when "table"
          table = block["content"]
          return [] unless table.is_a?(Hash) && table["type"] == "tableContent"

          Array(table["rows"]).flat_map { |row|
            Array(row["cells"]).map { |cell|
              cell_content = cell.is_a?(Hash) ? cell["content"] : cell
              inline_text(cell_content)
            }
          }
        else
          []
        end
      end

      # Converts an array of BlockNote blocks into a single plain text string.
      def blocks_to_text(blocks)
        Array(blocks).map { |b| extract_text(b) }
                     .join(" ")
                     .gsub(/[[:space:]]+/, " ")
                     .strip
      end

      # Normalizes BlockNote content from various formats (Array, Hash, String)
      # into an Array of blocks. Handles the legacy BlockNote v1 format
      # (doc > blockGroup > blockContainer > block) by unwrapping container
      # layers to produce a flat array of content blocks.
      def normalize(content)
        blocks = case content
        when Array  then content
        when Hash   then content.fetch("content", [])
        when String then normalize(JSON.parse(content))
        else []
        end

        unwrap_containers(blocks)
      rescue JSON::ParserError => e
        warn_malformed(e)
        []
      end

      WRAPPER_TYPES = %w[blockGroup blockContainer].freeze

      # Recursively unwraps blockGroup/blockContainer wrappers to extract
      # content blocks.
      def unwrap_containers(blocks)
        blocks.flat_map do |block|
          if WRAPPER_TYPES.include?(block["type"])
            unwrap_containers(Array(block["content"]))
          else
            block
          end
        end
      end

      def warn_malformed(error)
        return unless defined?(Rails) && Rails.respond_to?(:logger)

        Rails.logger&.warn("[Bali::BlockNote::Text] Malformed JSON content: #{error.message}")
      end
      private_class_method :warn_malformed
    end
  end
end
