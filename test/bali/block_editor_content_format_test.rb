# frozen_string_literal: true

require "test_helper"

# #1091 — el editor persiste en una de dos formas, y hasta acá cuál te tocaba no era
# decisión del host: encender `comments:` hacía que el PRIMER USUARIO QUE DEJARA UN
# COMENTARIO reescribiera la columna en la otra. Con auto-guardado eso pasaba sin que nadie
# lo pidiera, y todo lo que lee esa columna del lado de Rails se encontraba otro esquema.
class BaliBlockEditorContentFormatTest < ActiveSupport::TestCase
  BLOCKS = [ { "id" => "1", "type" => "paragraph", "props" => {}, "content" => [] } ].freeze
  PROSEMIRROR = { "type" => "doc", "content" => [ { "type" => "blockGroup" } ] }.freeze

  def test_an_array_of_blocks_is_the_blocks_shape
    assert_equal :blocks, Bali::BlockEditor.content_format(BLOCKS)
  end

  def test_a_doc_root_is_the_prosemirror_shape
    assert_equal :prosemirror, Bali::BlockEditor.content_format(PROSEMIRROR)
  end

  # La columna puede llegar parseada (`jsonb`) o como texto (`text`), y la pregunta es la
  # misma.
  def test_it_reads_json_text_too
    assert_equal :blocks, Bali::BlockEditor.content_format(BLOCKS.to_json)
    assert_equal :prosemirror, Bali::BlockEditor.content_format(PROSEMIRROR.to_json)
  end

  def test_a_hash_with_symbol_keys_is_read_the_same
    assert_equal :prosemirror, Bali::BlockEditor.content_format({ type: "doc", content: [] })
  end

  # Una columna que nunca tuvo contenido del editor no es ninguna de las dos, y decir que
  # sí sería peor que no responder.
  def test_anything_else_has_no_shape
    [ nil, "", "not json", {}, { "type" => "paragraph" }, 42 ].each do |value|
      assert_nil Bali::BlockEditor.content_format(value), value.inspect
    end
  end

  # Un array vacío ES contenido del editor: un documento en blanco.
  def test_an_empty_document_is_still_the_blocks_shape
    assert_equal :blocks, Bali::BlockEditor.content_format([])
  end
end
