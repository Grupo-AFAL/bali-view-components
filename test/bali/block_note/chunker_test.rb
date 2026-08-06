# frozen_string_literal: true

require "test_helper"

class BaliBlockNoteChunkerTest < ActiveSupport::TestCase
  HEADING_BLOCK = ->(id, text, level: 2) {
    {
      "id" => id,
      "type" => "heading",
      "props" => { "textColor" => "default", "textAlignment" => "left",
                   "backgroundColor" => "default", "level" => level },
      "content" => [ { "type" => "text", "text" => text, "styles" => {} } ],
      "children" => []
    }
  }

  PARAGRAPH_BLOCK = ->(id, text) {
    {
      "id" => id,
      "type" => "paragraph",
      "props" => { "textColor" => "default", "textAlignment" => "left", "backgroundColor" => "default" },
      "content" => [ { "type" => "text", "text" => text, "styles" => {} } ],
      "children" => []
    }
  }

  # Chunking respects document sections

  test "splits document into chunks by heading sections" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Establecer los lineamientos para el proceso."),
      HEADING_BLOCK.call("h2", "Alcance"),
      PARAGRAPH_BLOCK.call("p2", "Aplica a todas las áreas de la organización."),
      HEADING_BLOCK.call("h3", "Procedimiento"),
      PARAGRAPH_BLOCK.call("p3", "Seguir los pasos indicados en este documento.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_equal 3, chunks.length
  end

  test "each chunk corresponds to a natural document section" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Establecer los lineamientos para el proceso."),
      HEADING_BLOCK.call("h2", "Alcance"),
      PARAGRAPH_BLOCK.call("p2", "Aplica a todas las áreas de la organización.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_includes chunks[0][:content], "Objetivo"
    assert_includes chunks[1][:content], "Alcance"
  end

  test "preserves section title as metadata" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Texto del objetivo.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_equal "Objetivo", chunks[0][:section_title]
  end

  test "assigns sequential positions starting from zero" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Primero."),
      HEADING_BLOCK.call("h2", "Alcance"),
      PARAGRAPH_BLOCK.call("p2", "Segundo.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_equal 0, chunks[0][:position]
    assert_equal 1, chunks[1][:position]
  end

  test "includes token_count for each chunk" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Texto breve.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert chunks[0][:token_count] > 0
  end

  # Optimal chunk sizes

  test "long sections are subdivided with overlap" do
    # Build a section with ~2400 chars to force subdivision (target ~1600 chars)
    long_text = "Esta es una oración de prueba que se repite para generar contenido suficiente. " * 30
    blocks = [
      HEADING_BLOCK.call("h1", "Sección Larga"),
      PARAGRAPH_BLOCK.call("p1", long_text)
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert chunks.length > 1, "Long section should be split into multiple chunks"
  end

  test "subdivided chunks share overlap content" do
    long_text = "Esta es una oración de prueba que se repite para generar contenido suficiente. " * 30
    blocks = [
      HEADING_BLOCK.call("h1", "Sección Larga"),
      PARAGRAPH_BLOCK.call("p1", long_text)
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert chunks.length >= 2
    # The second chunk starts OVERLAP_CHARS before the end of the first chunk,
    # so its opening must be a literal substring of the first chunk.
    assert_includes chunks[0][:content], chunks[1][:content][0, 100],
                    "second chunk must start with content from the end of the first chunk"
  end

  test "every subdivided chunk keeps the section title" do
    long_text = "Contenido repetido para forzar la subdivisión del texto en partes. " * 40
    blocks = [
      HEADING_BLOCK.call("h1", "Sección Larga"),
      PARAGRAPH_BLOCK.call("p1", long_text)
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert chunks.length >= 2
    chunks.each { |chunk| assert_equal "Sección Larga", chunk[:section_title] }
  end

  test "chunk sizes stay near the target" do
    long_text = "Palabras que suman contenido para el verificador de tamaños de chunk. " * 50
    blocks = [ PARAGRAPH_BLOCK.call("p1", long_text) ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    chunks.each do |chunk|
      assert chunk[:content].length <= Bali::BlockNote::Chunker::TARGET_CHARS + Bali::BlockNote::Chunker::OVERLAP_CHARS,
             "chunk of #{chunk[:content].length} chars exceeds target + overlap"
    end
  end

  # Edge cases

  test "returns empty array for nil content" do
    chunks = Bali::BlockNote::Chunker.new(nil).call
    assert_equal [], chunks
  end

  test "returns empty array for empty blocks" do
    chunks = Bali::BlockNote::Chunker.new([]).call
    assert_equal [], chunks
  end

  test "returns empty array for invalid JSON string" do
    chunks = Bali::BlockNote::Chunker.new("not json{{{").call
    assert_equal [], chunks
  end

  test "accepts a JSON string of blocks" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Texto del objetivo.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks.to_json).call

    assert_equal 1, chunks.length
    assert_equal "Objetivo", chunks[0][:section_title]
  end

  test "accepts a Hash with a content key" do
    blocks = [
      HEADING_BLOCK.call("h1", "Objetivo"),
      PARAGRAPH_BLOCK.call("p1", "Texto del objetivo.")
    ]

    chunks = Bali::BlockNote::Chunker.new({ "content" => blocks }).call

    assert_equal 1, chunks.length
  end

  test "skips sections whose text is empty" do
    blocks = [
      PARAGRAPH_BLOCK.call("p1", ""),
      HEADING_BLOCK.call("h1", "Con texto"),
      PARAGRAPH_BLOCK.call("p2", "Contenido real.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_equal 1, chunks.length
    assert_equal "Con texto", chunks[0][:section_title]
  end

  test "handles content with no headings as single chunk" do
    blocks = [
      PARAGRAPH_BLOCK.call("p1", "Párrafo sin encabezado."),
      PARAGRAPH_BLOCK.call("p2", "Otro párrafo.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_equal 1, chunks.length
    assert_nil chunks[0][:section_title]
  end

  test "section_title is nil for chunk with no preceding heading" do
    blocks = [
      PARAGRAPH_BLOCK.call("p1", "Introducción sin encabezado.")
    ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    assert_nil chunks[0][:section_title]
  end

  test "token_count approximates character count divided by 4" do
    text = "a" * 400
    blocks = [ PARAGRAPH_BLOCK.call("p1", text) ]

    chunks = Bali::BlockNote::Chunker.new(blocks).call

    # ~100 tokens for 400 chars (4 chars/token approximation for Spanish)
    assert_in_delta 100, chunks[0][:token_count], 20
  end
end
