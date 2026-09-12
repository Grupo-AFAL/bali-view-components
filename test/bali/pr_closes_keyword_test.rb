# frozen_string_literal: true

require "test_helper"
require "open3"
require "tempfile"

# La guarda que impide abrir una PR que intenta cerrar un issue EN ESPAÑOL.
#
# GitHub solo cierra el issue al mergear con sus palabras clave, y todas son en
# inglés. «Cierra #123» se lee igual de bien, no cierra nada, y el issue se
# queda abierto sin que nadie se entere. Pasó decenas de veces, así que dejó de
# ser una regla escrita y pasó a ser una compuerta.
#
# Y la compuerta también se prueba: un hook que deja de disparar no falla — deja
# pasar, que es exactamente cómo se ve cuando funciona.
#
# `Rails.root` aquí es `spec/dummy`, no el repo: la ruta del hook cuelga de
# `Bali::Engine.root`, que es la raíz del gem — el mismo idioma que usan
# `i18n_usage_test` y `stimulus_target_guards_test`.
class PrClosesKeywordTest < ActiveSupport::TestCase
  HOOK = Bali::Engine.root.join(".claude/hooks/pr-closes-keyword.sh").freeze

  test "el hook existe y es ejecutable" do
    assert File.exist?(HOOK), "el hook desapareció"
    assert File.executable?(HOOK), "el hook tiene que poder correr sin `bash` delante"
  end

  test "está cableado como PreToolUse de Bash en .claude/settings.json" do
    ajustes = JSON.parse(Bali::Engine.root.join(".claude/settings.json").read)
    pre = ajustes.dig("hooks", "PreToolUse")

    refute_nil pre, "sin la entrada PreToolUse el hook nunca corre"
    comandos = pre.select { |e| e["matcher"] == "Bash" }.flat_map { |e| e["hooks"] }.map { |h| h["command"] }
    assert comandos.any? { |c| c.include?("pr-closes-keyword.sh") },
           "el hook tiene que estar bajo el matcher Bash: #{comandos.inspect}"
  end

  # --- lo que bloquea ---------------------------------------------------------

  test "bloquea un cuerpo en archivo que dice Cierra" do
    con_cuerpo("Cierra #963.\n\nTexto del PR.\n") do |ruta|
      estado, error = correr("gh pr create --repo x/y --body-file #{ruta}")

      assert_equal 2, estado, "2 es lo único que Claude lee como «no lo hagas»"
      assert_match(/Closes/, error, "el mensaje tiene que decir con qué reemplazarlo")
    end
  end

  test "bloquea también en pr edit, que es por donde se corrige un cuerpo" do
    con_cuerpo("Cierra #12\n") do |ruta|
      estado, = correr("gh pr edit 974 --repo x/y --body-file #{ruta}")
      assert_equal 2, estado
    end
  end

  test "bloquea el cuerpo pasado en línea con --body" do
    estado, = correr('gh pr create --body "Cierra #12 y algo más"')
    assert_equal 2, estado
  end

  test "bloquea los otros verbos que se escriben solos redactando en español" do
    %w[Resuelve Corrige Arregla].each do |verbo|
      con_cuerpo("#{verbo} #34\n") do |ruta|
        estado, = correr("gh pr create --body-file #{ruta}")
        assert_equal 2, estado, "«#{verbo} #34» tampoco cierra nada en GitHub"
      end
    end
  end

  # --- lo que NO puede bloquear -----------------------------------------------

  test "deja pasar el cuerpo correcto, con el resto en español" do
    con_cuerpo("Closes #963\n\nEl cuerpo sigue en español, que es lo normal aquí.\n") do |ruta|
      estado, = correr("gh pr create --repo x/y --body-file #{ruta}")
      assert_equal 0, estado
    end
  end

  test "no se mete con otros comandos" do
    [ "gh pr list --repo x/y", "echo Cierra #12", "git commit -m 'Cierra #12'" ].each do |cmd|
      estado, = correr(cmd)
      assert_equal 0, estado, "#{cmd} no publica ningún cuerpo de PR"
    end
  end

  test "una entrada que no entiende se deja pasar, no se traba" do
    # Una compuerta rota no puede volverse un tapón para todo lo demás.
    estado, = correr(nil, entrada: "esto no es json")
    assert_equal 0, estado
  end

  private

  def con_cuerpo(texto)
    archivo = Tempfile.new([ "cuerpo", ".md" ])
    archivo.write(texto)
    archivo.flush
    yield archivo.path
  ensure
    archivo&.close!
  end

  def correr(comando, entrada: nil)
    entrada ||= { tool_input: { command: comando } }.to_json
    salida, error, estado = Open3.capture3("bash", HOOK.to_s, stdin_data: entrada)
    [ estado.exitstatus, error, salida ]
  end
end
