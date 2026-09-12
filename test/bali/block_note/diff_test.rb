# frozen_string_literal: true

require "test_helper"

class BaliBlockNoteDiffTest < ActiveSupport::TestCase
  def build_block(type, text, level: nil)
    props = { "textColor" => "default", "textAlignment" => "left", "backgroundColor" => "default" }
    props["level"] = level if type == "heading"
    {
      "id" => SecureRandom.uuid,
      "type" => type,
      "props" => props,
      "content" => [ { "type" => "text", "text" => text, "styles" => {} } ],
      "children" => []
    }
  end

  def sample_content
    [
      build_block("heading", "Objetivo", level: 2),
      build_block("paragraph", "Establecer los lineamientos para compras."),
      build_block("heading", "Alcance", level: 2),
      build_block("paragraph", "Aplica a todas las areas.")
    ]
  end

  test "detects no changes when content is identical" do
    diff = Bali::BlockNote::Diff.new(sample_content, sample_content)

    assert_not diff.changes?
    assert_equal 0, diff.summary[:added]
    assert_equal 0, diff.summary[:modified]
    assert_equal 0, diff.summary[:removed]
    assert_equal 2, diff.summary[:unchanged]
  end

  test "detects added sections" do
    old_content = sample_content
    new_content = sample_content + [
      build_block("heading", "Responsables", level: 2),
      build_block("paragraph", "El jefe de compras es responsable.")
    ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)

    assert diff.changes?
    assert_equal 1, diff.summary[:added]
    assert_equal 2, diff.summary[:unchanged]

    added = diff.changed_sections.find { |s| s[:status] == :added }
    assert_equal "Responsables", added[:heading]
  end

  test "detects modified sections" do
    old_content = sample_content
    new_content = [
      build_block("heading", "Objetivo", level: 2),
      build_block("paragraph", "NUEVO texto del objetivo modificado."),
      build_block("heading", "Alcance", level: 2),
      build_block("paragraph", "Aplica a todas las areas.")
    ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)

    assert diff.changes?
    assert_equal 1, diff.summary[:modified]
    assert_equal 1, diff.summary[:unchanged]

    modified = diff.changed_sections.find { |s| s[:status] == :modified }
    assert_equal "Objetivo", modified[:heading]
  end

  test "detects removed sections" do
    old_content = sample_content
    new_content = [
      build_block("heading", "Objetivo", level: 2),
      build_block("paragraph", "Establecer los lineamientos para compras.")
    ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)

    assert diff.changes?
    assert_equal 1, diff.summary[:removed]
    assert_equal 1, diff.summary[:unchanged]

    removed = diff.changed_sections.find { |s| s[:status] == :removed }
    assert_equal "Alcance", removed[:heading]
  end

  test "reports section level from heading props" do
    old_content = []
    new_content = [
      build_block("heading", "Detalle", level: 3),
      build_block("paragraph", "Contenido.")
    ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)
    section = diff.changed_sections.find { |s| s[:heading] == "Detalle" }

    assert_equal 3, section[:level]
  end

  test "handles nil content gracefully" do
    diff = Bali::BlockNote::Diff.new(nil, nil)

    assert_not diff.changes?
    assert_equal({ added: 0, modified: 0, removed: 0, unchanged: 0 }, diff.summary)
  end

  test "handles empty arrays" do
    diff = Bali::BlockNote::Diff.new([], [])

    assert_not diff.changes?
  end

  test "treats all content as new when old is empty" do
    diff = Bali::BlockNote::Diff.new([], sample_content)

    assert diff.changes?
    assert_equal 2, diff.summary[:added]
  end

  test "annotated_blocks includes diff status" do
    base = sample_content
    new_content = base + [
      build_block("heading", "Nuevo", level: 2),
      build_block("paragraph", "Contenido nuevo.")
    ]

    diff = Bali::BlockNote::Diff.new(base, new_content)
    blocks = diff.annotated_blocks

    unchanged_blocks = blocks.select { |b| b["_diff_status"] == "unchanged" }
    added_blocks = blocks.select { |b| b["_diff_status"] == "added" }

    assert_equal 4, unchanged_blocks.size
    assert_equal 2, added_blocks.size
  end

  test "handles legacy hash format content" do
    legacy = { "content" => sample_content }
    diff = Bali::BlockNote::Diff.new(legacy, sample_content)

    assert_not diff.changes?
  end

  test "handles JSON string content" do
    json_str = sample_content.to_json
    diff = Bali::BlockNote::Diff.new(json_str, sample_content)

    assert_not diff.changes?
  end

  test "exposes normalized old_content and new_content" do
    diff = Bali::BlockNote::Diff.new(sample_content.to_json, nil)

    assert_equal 4, diff.old_content.size
    assert_equal [], diff.new_content
  end

  # --- Block-level diff ---

  test "unchanged blocks within a modified section are not marked as modified" do
    heading  = build_block("heading", "Objetivo", level: 2)
    para_a   = build_block("paragraph", "Primer párrafo sin cambios.")
    para_b   = build_block("paragraph", "Segundo párrafo que sí cambia.")
    para_c   = build_block("paragraph", "Tercer párrafo sin cambios.")

    old_content = [ heading, para_a, para_b, para_c ]

    modified_b = para_b.merge("content" => [ { "type" => "text", "text" => "Segundo párrafo MODIFICADO.", "styles" => {} } ])
    new_content = [ heading, para_a, modified_b, para_c ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)
    blocks = diff.annotated_blocks

    statuses = blocks.each_with_object({}) { |b, h| h[b["id"]] = b["_diff_status"] }

    assert_equal "unchanged", statuses[heading["id"]]
    assert_equal "unchanged", statuses[para_a["id"]], "para_a should be unchanged"
    assert_equal "modified",  statuses[modified_b["id"]], "para_b should be modified"
    assert_equal "unchanged", statuses[para_c["id"]], "para_c should be unchanged"
  end

  test "new block inserted into existing section is annotated as added" do
    heading = build_block("heading", "Alcance", level: 2)
    para_a  = build_block("paragraph", "Aplica a todas las áreas.")
    para_new = build_block("paragraph", "Párrafo nuevo agregado.")

    old_content = [ heading, para_a ]
    new_content = [ heading, para_a, para_new ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)
    blocks = diff.annotated_blocks

    added = blocks.select { |b| b["_diff_status"] == "added" }
    assert_equal 1, added.size
    assert_equal para_new["id"], added.first["id"]
  end

  test "block removed from section is included as removed" do
    heading = build_block("heading", "Alcance", level: 2)
    para_a  = build_block("paragraph", "Primer párrafo.")
    para_b  = build_block("paragraph", "Párrafo que se elimina.")

    old_content = [ heading, para_a, para_b ]
    new_content = [ heading, para_a ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)
    blocks = diff.annotated_blocks

    removed = blocks.select { |b| b["_diff_status"] == "removed" }
    assert_equal 1, removed.size
    assert_equal para_b["id"], removed.first["id"]
  end

  test "block with same id and same content is unchanged even when section has other changes" do
    heading  = build_block("heading", "Objetivo", level: 2)
    stable   = build_block("paragraph", "Este párrafo no cambia nunca.")
    changing = build_block("paragraph", "Este párrafo cambia.")

    old_content = [ heading, stable, changing ]
    modified_changing = changing.merge(
      "content" => [ { "type" => "text", "text" => "Este párrafo ya cambió.", "styles" => {} } ]
    )
    new_content = [ heading, stable, modified_changing ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)

    stable_block = diff.annotated_blocks.find { |b| b["id"] == stable["id"] }
    assert_equal "unchanged", stable_block["_diff_status"], "stable block must remain unchanged"
  end

  test "section level summary is unaffected by block level changes" do
    heading = build_block("heading", "Objetivo", level: 2)
    para    = build_block("paragraph", "Texto original.")
    modified_para = para.merge(
      "content" => [ { "type" => "text", "text" => "Texto modificado.", "styles" => {} } ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, para ], [ heading, modified_para ])

    assert_equal 1, diff.summary[:modified], "section-level summary should show 1 modified"
    assert_equal 0, diff.summary[:added]
    assert_equal 0, diff.summary[:removed]
  end

  test "removed section appears inline at its original position, not at the end" do
    sec_a_heading = build_block("heading", "Sección A", level: 2)
    sec_a_para    = build_block("paragraph", "Contenido A.")
    sec_b_heading = build_block("heading", "Sección B", level: 2)
    sec_b_para    = build_block("paragraph", "Contenido B — se elimina.")
    sec_c_heading = build_block("heading", "Sección C", level: 2)
    sec_c_para    = build_block("paragraph", "Contenido C.")

    old_content = [ sec_a_heading, sec_a_para, sec_b_heading, sec_b_para, sec_c_heading, sec_c_para ]
    new_content = [ sec_a_heading, sec_a_para, sec_c_heading, sec_c_para ]

    diff   = Bali::BlockNote::Diff.new(old_content, new_content)
    blocks = diff.annotated_blocks
    ids    = blocks.map { |b| b["id"] }

    # Removed section B must appear before section C, not at the end
    idx_b_heading = ids.index(sec_b_heading["id"])
    idx_c_heading = ids.index(sec_c_heading["id"])

    assert_not_nil idx_b_heading, "Removed section B heading must be present"
    assert idx_b_heading < idx_c_heading, "Removed section B must appear before section C"
    assert_equal "removed", blocks[idx_b_heading]["_diff_status"]
  end

  test "removed block appears inline at its original position within a section" do
    heading = build_block("heading", "Sección", level: 2)
    para_a  = build_block("paragraph", "Párrafo A.")
    para_b  = build_block("paragraph", "Párrafo B — se elimina.")
    para_c  = build_block("paragraph", "Párrafo C.")

    old_content = [ heading, para_a, para_b, para_c ]
    new_content = [ heading, para_a, para_c ]

    diff   = Bali::BlockNote::Diff.new(old_content, new_content)
    blocks = diff.annotated_blocks
    ids    = blocks.map { |b| b["id"] }

    idx_b = ids.index(para_b["id"])
    idx_c = ids.index(para_c["id"])

    assert_not_nil idx_b, "Removed para_b must be present"
    assert idx_b < idx_c, "Removed para_b must appear before para_c"
    assert_equal "removed", blocks[idx_b]["_diff_status"]
  end

  test "modified block carries _diff_spans with word-level changes" do
    heading  = build_block("heading", "Section", level: 2)
    old_para = build_block("paragraph", "The quick brown fox.")
    new_para = old_para.merge(
      "content" => [ { "type" => "text", "text" => "The quick red fox.", "styles" => {} } ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, old_para ], [ heading, new_para ])
    modified = diff.annotated_blocks.find { |b| b["_diff_status"] == "modified" }

    assert_not_nil modified, "expected a modified block"
    spans = modified["_diff_spans"]
    assert_not_nil spans, "modified block must carry _diff_spans"

    removed_texts = spans.select { |s| s["type"] == "removed" }.map { |s| s["text"] }.join
    added_texts   = spans.select { |s| s["type"] == "added"   }.map { |s| s["text"] }.join

    assert_includes removed_texts, "brown", "removed span should contain old word"
    assert_includes added_texts,   "red",   "added span should contain new word"
  end

  test "consecutive spans of the same type are merged" do
    heading  = build_block("heading", "Section", level: 2)
    old_para = build_block("paragraph", "hola mundo")
    new_para = old_para.merge(
      "content" => [ { "type" => "text", "text" => "hola querido mundo", "styles" => {} } ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, old_para ], [ heading, new_para ])
    modified = diff.annotated_blocks.find { |b| b["_diff_status"] == "modified" }
    spans = modified["_diff_spans"]

    # "querido" and the following space are two consecutive added tokens —
    # they must collapse into a single span, and no two adjacent spans may
    # share a type.
    added = spans.select { |s| s["type"] == "added" }
    assert_equal 1, added.size, "consecutive added tokens must collapse into one span"
    assert_equal "querido", added.first["text"].strip
    spans.each_cons(2) do |a, b|
      assert_not_equal a["type"], b["type"], "adjacent spans must not share a type: #{spans.inspect}"
    end

    # Reconstruction invariants: unchanged+removed spans rebuild the old text,
    # unchanged+added spans rebuild the new text.
    old_text = spans.reject { |s| s["type"] == "added" }.map { |s| s["text"] }.join
    new_text = spans.reject { |s| s["type"] == "removed" }.map { |s| s["text"] }.join
    assert_equal "hola mundo", old_text
    assert_equal "hola querido mundo", new_text
  end

  test "unchanged block within a modified section has no _diff_spans" do
    heading  = build_block("heading", "Section", level: 2)
    stable   = build_block("paragraph", "This does not change.")
    changing = build_block("paragraph", "This changes.")
    modified = changing.merge(
      "content" => [ { "type" => "text", "text" => "This has changed.", "styles" => {} } ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, stable, changing ], [ heading, stable, modified ])
    stable_block = diff.annotated_blocks.find { |b| b["id"] == stable["id"] }

    assert_equal "unchanged", stable_block["_diff_status"]
    assert_nil stable_block["_diff_spans"], "unchanged blocks must not carry _diff_spans"
  end

  test "handles duplicate section headings without silent data loss" do
    heading_a   = build_block("heading", "Notas", level: 2)
    para_a      = build_block("paragraph", "Primera sección de notas.")
    heading_b   = build_block("heading", "Cuerpo", level: 2)
    para_b      = build_block("paragraph", "Contenido del cuerpo.")
    heading_a2  = build_block("heading", "Notas", level: 2)
    para_a2     = build_block("paragraph", "Segunda sección de notas.")

    old_content = [ heading_a, para_a, heading_b, para_b, heading_a2, para_a2 ]

    # New content keeps only one "Notas" section
    new_content = [ heading_a, para_a, heading_b, para_b ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)

    assert_equal 1, diff.summary[:removed], "duplicate removed section must be counted"
    assert_equal 2, diff.summary[:unchanged]

    removed = diff.changed_sections.select { |s| s[:status] == :removed }
    assert_equal 1, removed.size
    assert_equal "Notas", removed.first[:heading]
  end

  test "extra duplicate section blocks are annotated as removed" do
    heading_a   = build_block("heading", "Notas", level: 2)
    para_a      = build_block("paragraph", "Primera sección de notas.")
    heading_a2  = build_block("heading", "Notas", level: 2)
    para_a2     = build_block("paragraph", "Segunda sección de notas.")

    old_content = [ heading_a, para_a, heading_a2, para_a2 ]
    new_content = [ heading_a, para_a ]

    diff = Bali::BlockNote::Diff.new(old_content, new_content)
    removed_ids = diff.annotated_blocks
                      .select { |b| b["_diff_status"] == "removed" }
                      .map { |b| b["id"] }

    assert_includes removed_ids, heading_a2["id"]
    assert_includes removed_ids, para_a2["id"]
  end

  # --- Structural granularity: entityReference and table cells ---

  def text_node(text)
    { "type" => "text", "text" => text, "styles" => {} }
  end

  def entity_reference_node(name, id: SecureRandom.hex(4), type: "GlossaryTerm")
    { "type" => "entityReference",
      "props" => { "entityType" => type, "entityId" => id, "entityName" => name } }
  end

  def paragraph_with(content)
    { "id" => SecureRandom.uuid, "type" => "paragraph",
      "props" => { "textColor" => "default", "textAlignment" => "left", "backgroundColor" => "default" },
      "content" => content,
      "children" => [] }
  end

  def table_block(rows)
    { "id" => SecureRandom.uuid, "type" => "table",
      "props" => { "textColor" => "default" },
      "content" => {
        "type" => "tableContent",
        "rows" => rows.map { |cells|
          { "cells" => cells.map { |c| { "content" => c } } }
        }
      },
      "children" => [] }
  end

  test "section is :modified when an entityReference is inserted into a paragraph" do
    heading = build_block("heading", "Glosario", level: 2)
    para = paragraph_with([ text_node("Sin referencias.") ])
    para_with_ref = para.merge(
      "content" => [
        text_node("Sin referencias. Ver "),
        entity_reference_node("Cliente prospecto"),
        text_node(".")
      ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, para ], [ heading, para_with_ref ])

    assert diff.changes?, "diff should detect the inserted entityReference"
    assert_equal 1, diff.summary[:modified]
  end

  test "block is :modified when plain text is replaced by an entityReference of the same visible name" do
    heading = build_block("heading", "Glosario", level: 2)
    para_plain = paragraph_with([ text_node("Define el SLA aplicable.") ])
    para_chip  = para_plain.merge(
      "content" => [
        text_node("Define el "),
        entity_reference_node("SLA"),
        text_node(" aplicable.")
      ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, para_plain ], [ heading, para_chip ])
    annotated = diff.annotated_blocks
    modified = annotated.find { |b| b["id"] == para_plain["id"] }

    assert_equal "modified", modified["_diff_status"],
                 "replacing plain text by an entityReference must register as a modification"
  end

  test "_diff_spans include the entityReference name when a chip replaces plain text" do
    heading = build_block("heading", "Glosario", level: 2)
    para_plain = paragraph_with([ text_node("Aplica al cliente prospecto en el flujo.") ])
    para_chip  = para_plain.merge(
      "content" => [
        text_node("Aplica al "),
        entity_reference_node("cliente prospecto"),
        text_node(" en el flujo.")
      ]
    )

    diff = Bali::BlockNote::Diff.new([ heading, para_plain ], [ heading, para_chip ])
    modified = diff.annotated_blocks.find { |b| b["_diff_status"] == "modified" }

    assert_not_nil modified
    spans = modified["_diff_spans"]
    assert_not_nil spans
    rendered = spans.map { |s| s["text"] }.join
    assert_includes rendered, "cliente prospecto"
  end

  test "table block is :modified when a cell value changes" do
    heading = build_block("heading", "Tabla", level: 2)
    old_table = table_block([
      [ [ text_node("Encabezado A") ], [ text_node("Encabezado B") ] ],
      [ [ text_node("valor original") ], [ text_node("dato fijo") ] ]
    ])
    new_table = old_table.deep_dup
    new_table["content"]["rows"][1]["cells"][0]["content"] = [ text_node("valor MODIFICADO") ]

    diff = Bali::BlockNote::Diff.new([ heading, old_table ], [ heading, new_table ])
    modified = diff.annotated_blocks.find { |b| b["id"] == old_table["id"] }

    assert_equal "modified", modified["_diff_status"]
    assert_equal 1, diff.summary[:modified]
  end

  test "table block is :modified when a cell text is replaced by an entityReference" do
    heading = build_block("heading", "Tabla con chip", level: 2)
    old_table = table_block([
      [ [ text_node("Riesgo") ], [ text_node("Mitigación") ] ],
      [ [ text_node("Falla del proveedor") ], [ text_node("activación de plan B") ] ]
    ])
    new_table = old_table.deep_dup
    new_table["content"]["rows"][1]["cells"][1]["content"] = [
      text_node("activación de "),
      entity_reference_node("Plan de continuidad"),
      text_node(".")
    ]

    diff = Bali::BlockNote::Diff.new([ heading, old_table ], [ heading, new_table ])
    modified = diff.annotated_blocks.find { |b| b["id"] == old_table["id"] }

    assert_equal "modified", modified["_diff_status"]
  end

  test "sections with regenerated block ids but identical shape are unchanged" do
    old_heading = build_block("heading", "Objetivo", level: 2)
    old_para    = build_block("paragraph", "Texto idéntico.")

    # Same visible structure, new UUIDs (BlockNote regenerates ids on paste).
    new_heading = old_heading.merge("id" => SecureRandom.uuid)
    new_para    = old_para.merge("id" => SecureRandom.uuid)

    diff = Bali::BlockNote::Diff.new([ old_heading, old_para ], [ new_heading, new_para ])

    assert_not diff.changes?, "id-only differences must not register as changes"
  end

  test "handles content without leading heading" do
    content_without_heading = [
      build_block("paragraph", "Intro paragraph without a heading."),
      build_block("paragraph", "Another paragraph."),
      build_block("heading", "First Section", level: 2),
      build_block("paragraph", "Section content.")
    ]

    diff = Bali::BlockNote::Diff.new([], content_without_heading)

    assert diff.changes?

    sections = diff.changed_sections
    # Should have a section with empty heading for the leading paragraphs
    untitled = sections.find { |s| s[:heading].empty? }
    assert_not_nil untitled, "Expected a section with an empty heading for leading paragraphs"
    assert_equal :added, untitled[:status]

    # And the named section
    named = sections.find { |s| s[:heading] == "First Section" }
    assert_not_nil named
    assert_equal :added, named[:status]
  end
end
