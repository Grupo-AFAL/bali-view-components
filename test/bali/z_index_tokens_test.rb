# frozen_string_literal: true

require "test_helper"

# Un token de la escala que no existe falla EN SILENCIO y hacia el lado equivocado: un host
# que declara `--bali-z-hovercard` porque la guía se lo dijo no ve ningún error, y tampoco ve
# el `9999` de respaldo —`zIndexFor` sólo cae ahí cuando la hoja de Bali no está en la
# página—, así que se queda con el valor del tier que sí existe y concluye que su override
# "no hace nada" sin saber por qué. Eso fue #851: la prosa de la guía de migración mandaba a
# definir un token que la gema nunca declaró, mientras su propia tabla, treinta líneas más
# arriba, decía lo correcto.
class BaliZIndexTokensTest < ActiveSupport::TestCase
  ENGINE_ROOT = Pathname.new(File.expand_path("../..", __dir__))
  SCALE = ENGINE_ROOT.join("app/assets/stylesheets/bali/z_index.css")

  # Sólo `docs/`, y a propósito: lo que se cuida es que la documentación no le PROMETA a un
  # host un token que nadie declara. El CHANGELOG es un registro de lo que pasó —incluida la
  # entrada que cuenta que este token equivocado se fue— y ahí nombrarlo es correcto.
  PROSE = Dir[ENGINE_ROOT.join("docs/**/*.md")].sort.freeze

  def declared_tokens
    SCALE.read.scan(/--bali-z-([a-z-]+)\s*:/).flatten.uniq.sort
  end

  def test_the_scale_declares_the_tiers_the_package_reads
    # Si esta lista cambia, cambió el contrato: el nombre de un tier es API para el host.
    assert_equal(
      %w[command drawer dropdown modal popover toast tooltip],
      declared_tokens
    )
  end

  def test_the_documentation_names_no_token_the_scale_does_not_declare
    known = declared_tokens
    offenders = PROSE.flat_map do |path|
      relative = Pathname.new(path).relative_path_from(ENGINE_ROOT)
      File.readlines(path).each_with_index.filter_map do |line, index|
        tokens = line.scan(/--bali-z-([a-z-]+)/).flatten.uniq - known
        "  #{relative}:#{index + 1} — --bali-z-#{tokens.first}" if tokens.any?
      end
    end

    assert_empty(
      offenders,
      "La documentación promete tokens que la escala no declara. Los tiers son " \
      "#{known.join(', ')}; un nombre fuera de esa lista no lo lee nadie y no avisa.\n" +
      offenders.join("\n")
    )
  end
end
