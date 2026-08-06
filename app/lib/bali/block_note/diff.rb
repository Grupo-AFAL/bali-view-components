# frozen_string_literal: true

require "diff/lcs"
require "digest"
require "json"
require "set"

module Bali
  module BlockNote
    # Computes a diff between two BlockNote JSON content arrays at two
    # granularities:
    #
    # - Section level (changed_sections / summary): groups blocks by heading,
    #   reports which sections were added, modified, removed, or unchanged.
    #   Used for badge summaries in diff views.
    #
    # - Block level (annotated_blocks): compares individual blocks by their
    #   BlockNote UUID. Within a modified section, blocks with the same ID are
    #   marked :unchanged or :modified based on content equality; new IDs are
    #   :added; removed IDs appear inline at their original position.
    #
    #   Modified blocks also carry "_diff_spans" — an array of {type, text}
    #   hashes from a word-level LCS diff, so a view can show exactly what
    #   changed inline.
    #
    # Pure Ruby (no ActiveSupport, no database). The word-level diff rides the
    # diff-lcs gem, declared as a dependency of the engine's gemspec.
    #
    # Usage:
    #   diff = Bali::BlockNote::Diff.new(old_content, new_content)
    #   diff.changed_sections # => [{ heading: "Scope", status: :modified }, ...]
    #   diff.summary          # => { added: 1, modified: 2, removed: 0, unchanged: 3 }
    #   diff.annotated_blocks # => blocks with "_diff_status" and optional "_diff_spans"
    class Diff
      Section = Data.define(:heading, :level, :blocks, :fingerprint)

      attr_reader :old_content, :new_content

      def initialize(old_content, new_content)
        @old_content = Bali::BlockNote::Text.normalize(old_content)
        @new_content = Bali::BlockNote::Text.normalize(new_content)
      end

      # Returns an array of hashes describing each section's change status.
      # Each hash: { heading:, level:, status: :added | :removed | :modified | :unchanged }
      def changed_sections
        @changed_sections ||= compute_changed_sections
      end

      def summary
        @summary ||= compute_summary
      end

      def changes?
        changed_sections.any? { |s| s[:status] != :unchanged }
      end

      # Returns annotated blocks for rendering: each block gets a
      # "_diff_status" key ("added", "removed", "modified", or "unchanged").
      # Modified blocks also carry "_diff_spans" for word-level inline diff
      # rendering. Removed blocks/sections appear inline at their original
      # position.
      def annotated_blocks
        @annotated_blocks ||= compute_annotated_blocks
      end

      private

      def old_sections
        @old_sections ||= extract_sections(old_content)
      end

      def new_sections
        @new_sections ||= extract_sections(new_content)
      end

      def extract_sections(blocks)
        sections = []
        current_heading = nil
        current_level = 0
        current_blocks = []

        blocks.each do |block|
          if block["type"] == "heading"
            # Save previous section
            if current_heading || current_blocks.any?
              sections << build_section(current_heading, current_level, current_blocks)
            end
            current_heading = extract_text(block)
            current_level = block.dig("props", "level") || 2
            current_blocks = [ block ]
          else
            current_blocks << block
          end
        end

        # Final section
        if current_heading || current_blocks.any?
          sections << build_section(current_heading, current_level, current_blocks)
        end

        sections
      end

      def build_section(heading, level, blocks)
        Section.new(heading: heading || "", level: level, blocks: blocks,
                    fingerprint: section_fingerprint(blocks))
      end

      # Structural fingerprint that hashes the section's JSON shape with block
      # IDs stripped. ID-stripping keeps two logically-identical sections equal
      # even when BlockNote regenerates UUIDs; preserving the rest of the shape
      # catches edits that share visible text but differ structurally — e.g.
      # swapping a plain word for an `entityReference` chip of the same name.
      def section_fingerprint(blocks)
        Digest::SHA256.hexdigest(JSON.generate(structural_signature(blocks)))
      end

      def structural_signature(value)
        case value
        when Array
          value.map { |v| structural_signature(v) }
        when Hash
          value.each_with_object({}) do |(k, v), out|
            next if k == "id" || k.start_with?("_diff")
            out[k] = structural_signature(v)
          end
        else
          value
        end
      end

      def extract_text(block)
        Bali::BlockNote::Text.extract_text(block)
      end

      def compute_changed_sections
        # Use a queue per heading to handle duplicate section headings without
        # data loss.
        old_queue = old_sections.each_with_object({}) do |sec, hash|
          (hash[sec.heading] ||= []) << sec
        end

        result = []

        new_sections.each do |new_sec|
          old_sec = old_queue[new_sec.heading]&.shift
          status = if old_sec.nil?
            :added
          elsif old_sec.fingerprint == new_sec.fingerprint
            :unchanged
          else
            :modified
          end
          result << { heading: new_sec.heading, level: new_sec.level, status: status }
        end

        # Remaining entries are old sections with no counterpart in new
        # (removed or extra duplicates).
        old_queue.each_value do |remaining|
          remaining.each do |old_sec|
            result << { heading: old_sec.heading, level: old_sec.level, status: :removed }
          end
        end

        result
      end

      def compute_summary
        counts = changed_sections.group_by { |s| s[:status] }.transform_values(&:size)
        { added: counts.fetch(:added, 0),
          modified: counts.fetch(:modified, 0),
          removed: counts.fetch(:removed, 0),
          unchanged: counts.fetch(:unchanged, 0) }
      end

      def compute_annotated_blocks
        # Queue per heading handles duplicate headings without silently
        # dropping sections.
        old_lookup = old_sections.each_with_object({}) do |sec, hash|
          (hash[sec.heading] ||= []) << sec
        end
        new_headings = new_sections.map(&:heading).to_set

        removed_before, trailing_removed =
          group_removed_before(old_sections, new_headings, &:heading)

        annotated = []

        new_sections.each do |new_sec|
          (removed_before[new_sec.heading] || []).each do |removed_sec|
            removed_sec.blocks.each { |b| annotated << b.merge("_diff_status" => "removed") }
          end

          old_sec = old_lookup[new_sec.heading]&.shift
          if old_sec.nil?
            new_sec.blocks.each { |b| annotated << b.merge("_diff_status" => "added") }
          elsif old_sec.fingerprint == new_sec.fingerprint
            new_sec.blocks.each { |b| annotated << b.merge("_diff_status" => "unchanged") }
          else
            annotated.concat(annotate_modified_blocks(old_sec.blocks, new_sec.blocks))
          end
        end

        # Extra occurrences of headings that exist in new but had more copies
        # in old. Non-surviving headings are already covered by removed_before
        # / trailing_removed.
        old_lookup.each do |heading, remaining|
          next unless new_headings.include?(heading)
          remaining.each do |sec|
            sec.blocks.each { |b| annotated << b.merge("_diff_status" => "removed") }
          end
        end

        trailing_removed.each do |removed_sec|
          removed_sec.blocks.each { |b| annotated << b.merge("_diff_status" => "removed") }
        end

        annotated
      end

      # Compares two block lists by block ID to produce fine-grained per-block
      # annotations. Removed blocks are inserted inline at their original
      # position in the old list. Modified blocks carry "_diff_spans" for
      # word-level inline rendering.
      def annotate_modified_blocks(old_blocks, new_blocks)
        old_by_id = old_blocks.select { |b| present_id?(b) }.to_h { |b| [ b["id"], b ] }
        new_ids   = new_blocks.filter_map { |b| b["id"] if present_id?(b) }.to_set

        removed_before, trailing_removed =
          group_removed_before(old_blocks, new_ids) { |b| b["id"] }

        result = []

        new_blocks.each do |block|
          (removed_before[block["id"]] || []).each do |removed_block|
            result << removed_block.merge("_diff_status" => "removed")
          end

          old_block = old_by_id[block["id"]]
          if old_block.nil?
            result << block.merge("_diff_status" => "added")
          elsif block_content_equal?(old_block, block)
            result << block.merge("_diff_status" => "unchanged")
          else
            result << block.merge(
              "_diff_status" => "modified",
              "_diff_spans"  => word_diff_spans(old_block, block)
            )
          end
        end

        trailing_removed.each { |b| result << b.merge("_diff_status" => "removed") }

        result
      end

      def present_id?(block)
        !block["id"].to_s.empty?
      end

      # Walks +items+ in order and groups removed items (those whose key is not
      # in +surviving_keys+) immediately before the next surviving item.
      # The block extracts the key from each item.
      #
      # Returns [removed_before_hash, trailing_array] where:
      #   removed_before_hash[key] = items removed just before that surviving key
      #   trailing_array           = items removed after the last surviving item
      def group_removed_before(items, surviving_keys)
        pending        = []
        removed_before = {}

        items.each do |item|
          key = yield(item)
          if surviving_keys.include?(key)
            removed_before[key] = pending if pending.any?
            pending = []
          else
            pending << item
          end
        end

        [ removed_before, pending ]
      end

      def block_content_equal?(block_a, block_b)
        block_a["type"]     == block_b["type"] &&
          block_a["content"]  == block_b["content"] &&
          block_a["props"]    == block_b["props"] &&
          block_a["children"] == block_b["children"]
      end

      # Returns an array of diff spans for word-level inline rendering.
      # Each span: { "type" => "unchanged"|"removed"|"added", "text" => "..." }
      def word_diff_spans(old_block, new_block)
        old_tokens = tokenize(plain_block_text(old_block))
        new_tokens = tokenize(plain_block_text(new_block))

        spans = []
        ::Diff::LCS.sdiff(old_tokens, new_tokens).each do |change|
          case change.action
          when "=" then spans << { "type" => "unchanged", "text" => change.new_element }
          when "+" then spans << { "type" => "added",     "text" => change.new_element }
          when "-" then spans << { "type" => "removed",   "text" => change.old_element }
          when "!"
            spans << { "type" => "removed", "text" => change.old_element }
            spans << { "type" => "added",   "text" => change.new_element }
          end
        end

        merge_consecutive_spans(spans)
      end

      def plain_block_text(block)
        Bali::BlockNote::Text.extract_text(block)
      end

      def tokenize(text)
        text.scan(/\S+|\s+/)
      end

      def merge_consecutive_spans(spans)
        spans.each_with_object([]) do |span, acc|
          if acc.last&.dig("type") == span["type"]
            acc.last["text"] += span["text"]
          else
            acc << span.dup
          end
        end
      end
    end
  end
end
