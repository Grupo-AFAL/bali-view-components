# frozen_string_literal: true

require "test_helper"

class BaliBlockNoteTextTest < ActiveSupport::TestCase
  HEADING = {
    "id" => "h1", "type" => "heading",
    "props" => { "textColor" => "default", "textAlignment" => "left",
                 "backgroundColor" => "default", "level" => 2 },
    "content" => [ { "type" => "text", "text" => "Objetivo", "styles" => {} } ],
    "children" => []
  }.freeze

  PARAGRAPH = {
    "id" => "p1", "type" => "paragraph",
    "props" => { "textColor" => "default", "textAlignment" => "left", "backgroundColor" => "default" },
    "content" => [ { "type" => "text", "text" => "Texto del párrafo.", "styles" => {} } ],
    "children" => []
  }.freeze

  TABLE_ROW = {
    "id" => "tr1", "type" => "tableRow",
    "cells" => [ [ { "type" => "text", "text" => "Celda 1" }, { "type" => "text", "text" => "Celda 2" } ] ],
    "content" => [],
    "children" => []
  }.freeze

  ENTITY_REFERENCE_BLOCK = {
    "id" => "p2", "type" => "paragraph",
    "props" => { "textColor" => "default", "textAlignment" => "left", "backgroundColor" => "default" },
    "content" => [
      { "type" => "text", "text" => "Ver el ", "styles" => {} },
      { "type" => "entityReference",
        "props" => { "entityType" => "GlossaryTerm", "entityId" => "42", "entityName" => "Cliente prospecto" } },
      { "type" => "text", "text" => " para más detalles.", "styles" => {} }
    ],
    "children" => []
  }.freeze

  TABLE_CONTENT_BLOCK = {
    "id" => "tab1", "type" => "table",
    "props" => { "textColor" => "default" },
    "content" => {
      "type" => "tableContent",
      "rows" => [
        { "cells" => [
          { "content" => [ { "type" => "text", "text" => "Cabecera A", "styles" => {} } ] },
          { "content" => [ { "type" => "text", "text" => "Cabecera B", "styles" => {} } ] }
        ] },
        { "cells" => [
          { "content" => [ { "type" => "text", "text" => "Valor 1", "styles" => {} } ] },
          { "content" => [ { "type" => "text", "text" => "Valor 2", "styles" => {} } ] }
        ] }
      ]
    },
    "children" => []
  }.freeze

  NESTED_BLOCK = {
    "id" => "n1", "type" => "paragraph",
    "content" => [ { "type" => "text", "text" => "Padre", "styles" => {} } ],
    "children" => [
      {
        "id" => "n2", "type" => "paragraph",
        "content" => [ { "type" => "text", "text" => "Hijo", "styles" => {} } ],
        "children" => []
      }
    ]
  }.freeze

  # extract_text

  test "extracts inline text from a block" do
    assert_equal "Objetivo", Bali::BlockNote::Text.extract_text(HEADING)
  end

  test "extracts text from nested children" do
    assert_equal "Padre Hijo", Bali::BlockNote::Text.extract_text(NESTED_BLOCK)
  end

  test "extracts text from deeply nested children" do
    block = {
      "id" => "n1", "type" => "paragraph",
      "content" => [ { "type" => "text", "text" => "Nivel 1", "styles" => {} } ],
      "children" => [
        { "id" => "n2", "type" => "paragraph",
          "content" => [ { "type" => "text", "text" => "Nivel 2", "styles" => {} } ],
          "children" => [
            { "id" => "n3", "type" => "paragraph",
              "content" => [ { "type" => "text", "text" => "Nivel 3", "styles" => {} } ],
              "children" => [] }
          ] }
      ]
    }
    assert_equal "Nivel 1 Nivel 2 Nivel 3", Bali::BlockNote::Text.extract_text(block)
  end

  test "extracts text from table row cells" do
    result = Bali::BlockNote::Text.extract_text(TABLE_ROW)
    assert_includes result, "Celda 1"
    assert_includes result, "Celda 2"
  end

  test "returns empty string for block with no content" do
    block = { "id" => "e1", "type" => "paragraph", "content" => [], "children" => [] }
    assert_equal "", Bali::BlockNote::Text.extract_text(block)
  end

  test "ignores whitespace-only inline text when joining parts" do
    block = {
      "id" => "w1", "type" => "paragraph",
      "content" => [ { "type" => "text", "text" => "   ", "styles" => {} } ],
      "children" => [
        { "id" => "w2", "type" => "paragraph",
          "content" => [ { "type" => "text", "text" => "Solo el hijo", "styles" => {} } ],
          "children" => [] }
      ]
    }
    assert_equal "Solo el hijo", Bali::BlockNote::Text.extract_text(block)
  end

  # entityReference inline nodes

  test "includes entityReference entityName when extracting inline text" do
    result = Bali::BlockNote::Text.extract_text(ENTITY_REFERENCE_BLOCK)
    assert_includes result, "Cliente prospecto"
    assert_includes result, "Ver el"
    assert_includes result, "para más detalles."
  end

  test "extracts text from a block that is solely an entityReference" do
    block = {
      "id" => "p3", "type" => "paragraph",
      "content" => [
        { "type" => "entityReference",
          "props" => { "entityType" => "Document", "entityId" => "7", "entityName" => "POL-001" } }
      ],
      "children" => []
    }
    assert_equal "POL-001", Bali::BlockNote::Text.extract_text(block)
  end

  # inline_text / inline_node_text edge cases

  test "inline_text returns empty string for non-array content" do
    assert_equal "", Bali::BlockNote::Text.inline_text(nil)
    assert_equal "", Bali::BlockNote::Text.inline_text({ "type" => "tableContent" })
    assert_equal "", Bali::BlockNote::Text.inline_text("raw string")
  end

  test "inline_node_text ignores unknown node types and non-hash nodes" do
    assert_nil Bali::BlockNote::Text.inline_node_text({ "type" => "unknownType", "text" => "x" })
    assert_nil Bali::BlockNote::Text.inline_node_text("not a hash")
    assert_nil Bali::BlockNote::Text.inline_node_text(nil)
  end

  # table blocks with tableContent shape

  test "extracts cell text from a table block in tableContent shape" do
    result = Bali::BlockNote::Text.extract_text(TABLE_CONTENT_BLOCK)
    assert_includes result, "Cabecera A"
    assert_includes result, "Cabecera B"
    assert_includes result, "Valor 1"
    assert_includes result, "Valor 2"
  end

  test "extracts entityReference inside a table cell" do
    block = {
      "id" => "tab2", "type" => "table",
      "content" => {
        "type" => "tableContent",
        "rows" => [
          { "cells" => [
            { "content" => [
              { "type" => "entityReference",
                "props" => { "entityType" => "GlossaryTerm", "entityId" => "9", "entityName" => "SLA" } }
            ] }
          ] }
        ]
      },
      "children" => []
    }
    assert_includes Bali::BlockNote::Text.extract_text(block), "SLA"
  end

  test "table block whose content is not tableContent yields no cell text" do
    block = { "id" => "tab3", "type" => "table", "content" => { "type" => "other" }, "children" => [] }
    assert_equal [], Bali::BlockNote::Text.table_cell_text(block)
  end

  test "table_cell_text returns empty array for non-table blocks" do
    assert_equal [], Bali::BlockNote::Text.table_cell_text(PARAGRAPH)
  end

  # blocks_to_text

  test "joins multiple blocks into single string" do
    result = Bali::BlockNote::Text.blocks_to_text([ HEADING, PARAGRAPH ])
    assert_equal "Objetivo Texto del párrafo.", result
  end

  test "collapses runs of whitespace into single spaces" do
    block = {
      "id" => "s1", "type" => "paragraph",
      "content" => [ { "type" => "text", "text" => "  Espacios \n\t dobles  ", "styles" => {} } ],
      "children" => []
    }
    assert_equal "Espacios dobles", Bali::BlockNote::Text.blocks_to_text([ block ])
  end

  test "returns empty string for empty array" do
    assert_equal "", Bali::BlockNote::Text.blocks_to_text([])
  end

  test "handles nil input" do
    assert_equal "", Bali::BlockNote::Text.blocks_to_text(nil)
  end

  # normalize

  test "normalizes Array input as-is" do
    blocks = [ HEADING ]
    assert_equal blocks, Bali::BlockNote::Text.normalize(blocks)
  end

  test "normalizes Hash with content key" do
    input = { "content" => [ HEADING ] }
    assert_equal [ HEADING ], Bali::BlockNote::Text.normalize(input)
  end

  test "normalizes Hash without content key to empty array" do
    assert_equal [], Bali::BlockNote::Text.normalize({ "type" => "doc" })
  end

  test "normalizes JSON string" do
    json = [ HEADING ].to_json
    result = Bali::BlockNote::Text.normalize(json)
    assert_equal 1, result.length
    assert_equal "heading", result.first["type"]
  end

  test "returns empty array for nil" do
    assert_equal [], Bali::BlockNote::Text.normalize(nil)
  end

  test "returns empty array for invalid JSON string" do
    assert_equal [], Bali::BlockNote::Text.normalize("not valid json{{{")
  end

  test "returns empty array for empty string" do
    assert_equal [], Bali::BlockNote::Text.normalize("")
  end

  test "returns empty array for unexpected type" do
    assert_equal [], Bali::BlockNote::Text.normalize(42)
  end

  # normalize: legacy BlockNote v1 wrappers

  test "unwraps blockGroup and blockContainer wrappers" do
    legacy = [
      { "type" => "blockGroup",
        "content" => [
          { "type" => "blockContainer", "content" => [ HEADING ] },
          { "type" => "blockContainer", "content" => [ PARAGRAPH ] }
        ] }
    ]
    result = Bali::BlockNote::Text.normalize(legacy)
    assert_equal %w[heading paragraph], result.map { |b| b["type"] }
  end

  test "unwraps nested wrappers recursively" do
    legacy = [
      { "type" => "blockGroup",
        "content" => [
          { "type" => "blockGroup",
            "content" => [ { "type" => "blockContainer", "content" => [ PARAGRAPH ] } ] }
        ] }
    ]
    result = Bali::BlockNote::Text.normalize(legacy)
    assert_equal [ PARAGRAPH ], result
  end

  test "keeps regular blocks intact while unwrapping siblings" do
    mixed = [
      HEADING,
      { "type" => "blockGroup", "content" => [ PARAGRAPH ] }
    ]
    result = Bali::BlockNote::Text.normalize(mixed)
    assert_equal [ HEADING, PARAGRAPH ], result
  end
end
