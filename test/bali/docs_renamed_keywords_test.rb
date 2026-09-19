# frozen_string_literal: true

require "test_helper"

# Un keyword renombrado que la guía sigue enseñando falla RUIDOSAMENTE, pero tarde y en el
# lugar equivocado: el host copia el ejemplo, el componente levanta `ArgumentError` y lo
# único que tiene para entenderlo es la misma página que se lo acaba de recomendar. Eso fue
# #1159: la sección WorkflowSteps ofreció `Component.new(variant: :horizontal)` durante tres
# minors —carácter por carácter la misma llamada que
# test/bali/components/workflow_steps_test.rb usa para probar que el guardia revienta—
# mientras la sección Stepper, veintiséis líneas más arriba, ya decía `orientation:`.
#
# Los guardias de los componentes son media promesa: dicen el nombre nuevo a quien ya se
# equivocó. Esta prueba es la otra media: lo que la gema rechaza en tiempo de ejecución, la
# documentación no lo ofrece.
#
# QUÉ ATAJA, EXACTAMENTE. Reconoce FORMAS, no intenciones. Ofrecer un keyword y nombrar un
# rename son cosas distintas —esta misma corrección escribe «It was `variant:` in the v3.1
# betas», que debe quedar verde—, así que cada keyword se busca en las formas concretas con
# las que la documentación lo reparte: la llamada, el `keyword: valor` y la viñeta de
# opciones que lo encabeza. Un keyword rechazado mencionado de otro modo no lo ataja, y esa
# es la línea que la prueba puede sostener: no promete «ningún uso», promete «ninguna de
# estas formas».
class BaliDocsRenamedKeywordsTest < ActiveSupport::TestCase
  ENGINE_ROOT = Pathname.new(File.expand_path("../..", __dir__))
  DOCS_GLOB = ENGINE_ROOT.join("docs/**/*.md").to_s

  # La guía de migración es la excepción, y es su razón de ser: documenta cada rename con el
  # par `<%# beta %>` / `<%# now %>`, así que el keyword viejo TIENE que aparecer ahí.
  MIGRATION_GUIDE = ENGINE_ROOT.join("docs/guides/migration-v3-to-v31.md").to_s

  # `docs/` no es toda la documentación que el host lee. El README es su primera página, y
  # las anotaciones de los `preview.rb` son prosa que Lookbook le sirve al mismo lector —de
  # hecho la frase que este PR corrige bajó de una de ellas, así que son el aguas arriba de
  # la guía, no un extra.
  SOURCES = (
    Dir[DOCS_GLOB] +
    [ ENGINE_ROOT.join("README.md").to_s ] +
    Dir[ENGINE_ROOT.join("app/components/bali/**/preview.rb").to_s]
  ).sort.freeze

  PROSE = (SOURCES - [ MIGRATION_GUIDE ]).freeze

  # Cada entrada es un keyword que la gema rechaza HOY con un guardia propio, así que un
  # ejemplo que lo use no está anticuado: está roto. `rename` nombra el reemplazo y el
  # archivo donde vive el guardia, que es lo que hay que leer si esta prueba falla; `shapes`
  # son las formas de repartirlo, nombradas para que la falla diga cuál se coló.
  #
  # Los patrones de llamada aceptan el keyword en CUALQUIER posición (`[^)]*`): en #1159 el
  # de WorkflowSteps exigía que fuera el primer argumento, y `new(progress: false, variant:
  # :horizontal)` se le escapaba.
  REJECTED = [
    {
      rename: "`variant:` → `orientation:` (app/components/bali/workflow_steps/component.rb)",
      shapes: {
        "la llamada" => /WorkflowSteps::Component\.new\([^)]*\bvariant:/,
        # Ningún componente de Bali toma `variant:` con estos valores —los buscamos: el eje
        # se llama `orientation:` en todos—, así que esta forma sólo puede ser el keyword
        # renombrado, venga en prosa o dentro de un ejemplo.
        "el keyword con su valor" => /\bvariant:\s*:(?:vertical|horizontal)\b/,
        # La viñeta de opciones: es lo que ojea quien está aprendiendo la API, antes de
        # llegar al bloque de código. `variant` encabezando una viñeta que documenta valores
        # de orientación no es ambiguo; el `variant` de Button o Pagination lista colores.
        "la viñeta de opciones" => /^[ \t]*[-*][ \t]*`variant`[^\n]*`:(?:vertical|horizontal)`/
      }
    },
    {
      rename: "`label:` → `aria_label:` (app/components/bali/topbar/icon_action/component.rb)",
      # Sólo la llamada: el valor es una cadena libre y `label:` es un keyword legítimo en
      # media biblioteca, así que fuera del paréntesis del componente no hay forma de
      # distinguir el rechazado del bueno sin falsos positivos.
      shapes: { "la llamada" => /IconAction::Component\.new\([^)]*\blabel:/ }
    },
    {
      rename: "`search_label:` → `search_aria_label:` (lib/bali/filter_form.rb)",
      shapes: { "el keyword" => /\bsearch_label:/ }
    },
    {
      rename: "search_fields `label:` → `aria_label:` (lib/bali/filter_form/search_configuration.rb)",
      # `\b` no muerde dentro de `aria_label:` —el guion bajo es carácter de palabra—, así
      # que el nombre bueno no dispara.
      shapes: { "la llamada del DSL" => /search_fields[^\n]*\blabel:/ }
    }
  ].freeze

  # Si la ruta de la excepción se escribe mal, o el glob la devuelve normalizada de otro
  # modo, la resta no quita nada y la prueba se vuelve verde por el lado tonto: seguiría
  # pasando, pero dejaría de cuidar la guía de migración. `assert_includes` sobre el glob es
  # lo que de verdad ata las dos formas de nombrar el archivo; restarla de una lista que la
  # contiene por construcción no prueba nada.
  def test_the_migration_guide_is_actually_excluded
    assert_path_exists(MIGRATION_GUIDE)
    assert_includes(Dir[DOCS_GLOB], MIGRATION_GUIDE)
    assert_not_includes(PROSE, MIGRATION_GUIDE)
    assert_equal(SOURCES.size - 1, PROSE.size)
    assert_not_empty(PROSE)
  end

  def test_the_documentation_offers_no_keyword_the_components_reject
    hits = PROSE.flat_map do |path|
      content = File.read(path)
      relative = Pathname.new(path).relative_path_from(ENGINE_ROOT)

      REJECTED.flat_map do |keyword|
        keyword[:shapes].flat_map do |shape, pattern|
          content.to_enum(:scan, pattern).map do
            line = content[0, Regexp.last_match.begin(0)].count("\n") + 1
            [ "#{relative}:#{line}", keyword[:rename], shape ]
          end
        end
      end
    end

    # Una misma línea puede caer por dos formas a la vez —el ejemplo copiable de #1159 es la
    # llamada Y el `keyword: valor`—: es un solo sitio que arreglar, no dos.
    offenders = hits.group_by { |where, rename, _| [ where, rename ] }.map do |(where, rename), group|
      "  #{where} — #{rename} [#{group.map(&:last).join(', ')}]"
    end.sort

    assert_empty(
      offenders,
      "La documentación ofrece keywords que la gema rechaza. Un host que copie el ejemplo " \
      "no obtiene una advertencia: obtiene un ArgumentError.\n" + offenders.join("\n")
    )
  end
end
