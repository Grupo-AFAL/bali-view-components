# frozen_string_literal: true

require "test_helper"
require "ripper"

# Los previews de Icon 500eaban con `uninitialized constant Bali::Icon::Preview::LucideMapping`
# (#843) y ningún test lo veía, porque el defecto no está en el componente sino en cómo el
# archivo de preview *nombra* a sus vecinos.
#
# `Module.nesting` se captura al parsear y guarda una referencia al objeto módulo, no al nombre.
# Lookbook carga `preview.rb` al arrancar para armar su navegación, capturando el `Bali::Icon`
# de ese momento; un `reload!` posterior descarta ese módulo y crea otro, y la constante hermana
# se autoloadea dentro del nuevo mientras el nesting del preview sigue apuntando al viejo. La
# constante existe, `bin/rails runner` la resuelve, y aun así el request muere.
#
# De ahí las dos mitades de este archivo: pedir los previews por HTTP —el único camino donde el
# defecto se manifiesta— y prohibir estáticamente el patrón en todos los `preview.rb`, para no
# depender de que alguien se acuerde de agregar el request cuando sume un preview.
class IconPreviewsTest < ActionDispatch::IntegrationTest
  # Los cinco que leen una constante hermana, más `default` como control.
  PREVIEWS = %w[
    lucide_mapped_icons
    brand_icons
    regional_icons
    custom_domain_icons
    all_existing_icons
    default
  ].freeze

  def test_every_icon_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/icon/#{name}"
      assert_response :ok, "/lookbook/preview/bali/icon/#{name} no renderizó"
    end
  end

  def test_the_catalog_previews_render_their_icons_and_not_an_empty_list
    { "lucide_mapped_icons" => Bali::Icon::LucideMapping.bali_names.size,
      "brand_icons" => Bali::Icon::KeptIcons::BRAND_PAYMENT.size +
                       Bali::Icon::KeptIcons::BRAND_SOCIAL.size,
      "regional_icons" => Bali::Icon::KeptIcons::REGIONAL.size,
      "custom_domain_icons" => Bali::Icon::KeptIcons::CUSTOM.size }.each do |name, count|
      get "/lookbook/preview/bali/icon/#{name}"
      assert_response :ok
      assert_select ".icon-component", { minimum: count },
        "#{name} listó menos iconos que los que declara su constante"
    end
  end

  # El guard estático. Una constante hermana escrita sin calificar dentro de un `preview.rb`
  # resuelve contra el objeto módulo capturado en el nesting, así que es la misma bomba de
  # #843 esperando a que un reload la active — sin importar de qué componente se trate.
  def test_no_preview_file_references_a_sibling_constant_unqualified
    offenders = preview_files.flat_map { |path| unqualified_sibling_references(path) }

    assert_empty offenders, <<~MSG
      Estos `preview.rb` nombran una constante hermana sin calificar. Escribila completa
      (`Bali::Icon::LucideMapping`, no `LucideMapping`) para que se resuelva contra el módulo
      vigente en el momento de la llamada y no contra el que capturó `Module.nesting`:

      #{offenders.join("\n")}
    MSG
  end

  # El guard sirve de poco si no ve a la mitad de las hermanas. `Bali::Widget` es el primer
  # namespace de la gema que abarca dos raíces de autoload, y ahí se notó: `sibling_constants`
  # solo miraba el directorio del propio preview, así que descubría `Component` y no `Base`
  # ni las clases de patrón. Este test fija que las descubra todas, porque la única señal de que
  # falta una es un 500 en la request — nunca en `bin/rails runner`.
  def test_sibling_discovery_spans_both_autoload_roots
    preview = Bali::Engine.root.join("app/components/bali/widget/preview.rb").to_s
    siblings = send(:sibling_constants, preview)

    assert_includes siblings, "Component", "app/components/bali/widget/component.rb"
    assert_includes siblings, "Base", "app/lib/bali/widget/base.rb"
    assert_includes siblings, "ListBase", "app/lib/bali/widget/list_base.rb"
    assert_includes siblings, "TrendBase", "app/lib/bali/widget/trend_base.rb"
  end

  private

  def preview_files
    Dir[Bali::Engine.root.join("app/components/bali/*/preview.rb")].sort
  end

  # Los nombres de constante que Zeitwerk define *dentro* del namespace del componente: un
  # archivo o un directorio hermano de `preview.rb`.
  def sibling_constants(preview_path)
    dir = File.dirname(preview_path)
    # El namespace de un componente puede abarcar DOS raíces de autoload: `app/components`
    # y `app/lib`. `Bali::Widget::Component` vive en la primera y `Bali::Widget::Base`,
    # `Result` y `Row` en la segunda — Zeitwerk las define todas dentro del MISMO módulo,
    # así que son hermanas por igual y el bug de #843 les aplica por igual. Mirar solo el
    # directorio del preview dejaba ciegas a las de `app/lib`: un `Result.new` pelado ahí
    # pasaba el guard y reventaba en la request.
    dirs = [ dir, Bali::Engine.root.join("app/lib/bali", File.basename(dir)).to_s ]

    # Un directorio sin `.rb` adentro (`previews/`, `svg/`) no es un namespace para Zeitwerk.
    basenames = dirs.flat_map do |d|
      Dir["#{d}/*.rb"].map { |f| File.basename(f, ".rb") } +
        Dir["#{d}/*/"].select { |sub| Dir["#{sub}**/*.rb"].any? }.map { |sub| File.basename(sub) }
    end

    basenames.reject { |b| b == "preview" }
             .map { |b| b.split("_").map(&:capitalize).join }
             .uniq
  end

  # Ripper en vez de una expresión regular: hay que distinguir la constante `Item` de la
  # cadena `'Item 1'` y del método `with_item`, y una regex sobre el texto crudo no puede.
  def unqualified_sibling_references(preview_path)
    siblings = sibling_constants(preview_path)
    return [] if siblings.empty?

    relative = Pathname(preview_path).relative_path_from(Bali::Engine.root)
    previous = nil

    Ripper.lex(File.read(preview_path)).filter_map do |(line, _col), type, token|
      was_scope_operator = previous == "::"
      previous = token unless type == :on_sp || type == :on_ignored_nl || type == :on_nl

      next if type != :on_const || was_scope_operator || !siblings.include?(token)

      "  #{relative}:#{line} — #{token}"
    end
  end
end
