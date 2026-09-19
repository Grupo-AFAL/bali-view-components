# frozen_string_literal: true

require "test_helper"

# #1091 — the editor persists in one of two shapes, and until now which one you got was not the
# host's decision: turning `comments:` on made the FIRST USER TO LEAVE A COMMENT rewrite the column
# in the other. With autosaving that happened without anybody asking for it, and everything reading
# that column on the Rails side found a different schema.
class BaliBlockEditorContentFormatTest < ActiveSupport::TestCase
  BLOCKS = [ { "id" => "1", "type" => "paragraph", "props" => {}, "content" => [] } ].freeze
  PROSEMIRROR = { "type" => "doc", "content" => [ { "type" => "blockGroup" } ] }.freeze

  def test_an_array_of_blocks_is_the_blocks_shape
    assert_equal :blocks, Bali::BlockEditor.content_format(BLOCKS)
  end

  def test_a_doc_root_is_the_prosemirror_shape
    assert_equal :prosemirror, Bali::BlockEditor.content_format(PROSEMIRROR)
  end

  # The column can arrive parsed (`jsonb`) or as text (`text`), and the question is the same.
  def test_it_reads_json_text_too
    assert_equal :blocks, Bali::BlockEditor.content_format(BLOCKS.to_json)
    assert_equal :prosemirror, Bali::BlockEditor.content_format(PROSEMIRROR.to_json)
  end

  def test_a_hash_with_symbol_keys_is_read_the_same
    assert_equal :prosemirror, Bali::BlockEditor.content_format({ type: "doc", content: [] })
  end

  # A column that never held editor content is neither of the two, and saying it is would be worse
  # than not answering.
  def test_anything_else_has_no_shape
    [ nil, "", "not json", {}, { "type" => "paragraph" }, 42 ].each do |value|
      assert_nil Bali::BlockEditor.content_format(value), value.inspect
    end
  end

  # An empty array IS editor content: a blank document.
  def test_an_empty_document_is_still_the_blocks_shape
    assert_equal :blocks, Bali::BlockEditor.content_format([])
  end
end
