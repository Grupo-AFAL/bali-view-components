# frozen_string_literal: true

module Bali
  module BlockNote
    # Splits a BlockNote JSON document into semantic chunks respecting heading
    # structure. Useful for search indexing and RAG pipelines — embeddings and
    # vector storage stay host-side (this lib is pure Ruby, no pgvector).
    #
    # Strategy:
    #   1. Group blocks by heading boundaries — each heading starts a new chunk.
    #   2. If a group's text exceeds TARGET_CHARS, subdivide with OVERLAP_CHARS
    #      overlap.
    #   3. Token count is approximated at 4 chars/token (typical for Spanish
    #      text).
    #
    # Returns an Array of hashes:
    #   { content: String, section_title: String|nil, position: Integer,
    #     token_count: Integer }
    class Chunker
      TARGET_CHARS  = 1_600  # ~400 tokens at 4 chars/token
      OVERLAP_CHARS = 300    # ~80 tokens overlap between subdivisions

      def initialize(blocks)
        @blocks = blocks
      end

      def call
        blocks = Bali::BlockNote::Text.normalize(@blocks)
        return [] if blocks.empty?

        sections = split_into_sections(blocks)
        chunks = sections.flat_map { |section| subdivide(section) }
        chunks.each_with_index.map do |chunk, idx|
          chunk.merge(position: idx)
        end
      end

      private

      # Groups blocks into sections delimited by heading blocks.
      # Returns Array of { title: String|nil, blocks: Array }
      def split_into_sections(blocks)
        sections = []
        current_title = nil
        current_blocks = []

        blocks.each do |block|
          if block["type"] == "heading"
            sections << { title: current_title, blocks: current_blocks } if current_blocks.any?
            current_title = Bali::BlockNote::Text.extract_text(block)
            current_blocks = [ block ]
          else
            current_blocks << block
          end
        end

        sections << { title: current_title, blocks: current_blocks } if current_blocks.any?
        sections
      end

      # Subdivides a section into chunks of TARGET_CHARS with OVERLAP_CHARS
      # overlap when the section text exceeds TARGET_CHARS. Snaps to word
      # boundaries.
      def subdivide(section)
        title = section[:title]
        text  = Bali::BlockNote::Text.blocks_to_text(section[:blocks])

        return [] if text.empty?

        if text.length <= TARGET_CHARS
          return [ build_chunk(text, title) ]
        end

        parts = []
        start = 0

        while start < text.length
          target_end = start + TARGET_CHARS
          slice_end = snap_to_word_boundary(text, target_end)
          parts << build_chunk(text[start...slice_end], title)
          break if slice_end >= text.length

          start = slice_end - OVERLAP_CHARS
        end

        parts
      end

      def snap_to_word_boundary(text, target_end)
        return text.length if target_end >= text.length

        pos = text.rindex(" ", target_end)
        pos && pos > target_end - OVERLAP_CHARS ? pos : target_end
      end

      def build_chunk(content, section_title)
        {
          content: content,
          section_title: section_title,
          token_count: estimate_tokens(content)
        }
      end

      def estimate_tokens(text)
        (text.length / 4.0).ceil
      end
    end
  end
end
