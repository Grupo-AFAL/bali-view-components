# frozen_string_literal: true

require "test_helper"

# `Tool` responde dos preguntas: "¿existe esta herramienta en este ambiente?" y "¿a dónde
# apunta?". La primera la contesta preguntándole a un CONTEXTO QUE RECIBE — nunca a
# `Rails.application.routes.url_helpers`. Por eso estas pruebas usan un doble y no montan
# rutas: es la ventaja concreta de recibir el contexto en vez de buscarlo.
class BaliTopbarToolsMenuToolTest < ComponentTestCase
  # Un contexto de vista de mentiras: responde sólo a los helpers que se le declaran.
  class FakeContext
    def initialize(rutas = {})
      @rutas = rutas
    end

    def respond_to?(name, include_all = false)
      @rutas.key?(name) || super
    end

    def public_send(name, *args)
      @rutas.key?(name) ? @rutas[name] : super
    end
  end

  def tool(**overrides)
    Bali::Topbar::ToolsMenu::Tool.new(
      **{ key: :letter_opener, icon: "mail-open", route_helper: :letter_opener_web_path }.merge(overrides)
    )
  end

  def test_a_mounted_tool_is_available_when_the_context_knows_its_helper
    context = FakeContext.new(letter_opener_web_path: "/letter_opener")

    assert tool.available?(context)
    assert_equal "/letter_opener", tool.href(context)
  end

  def test_a_mounted_tool_is_not_available_when_the_context_does_not_know_its_helper
    assert_not tool.available?(FakeContext.new)
  end

  def test_an_external_tool_is_available_when_its_url_resolves
    external = tool(key: :repository, route_helper: nil, url: -> { "https://example.test/repo" })

    assert external.available?(FakeContext.new)
    assert_equal "https://example.test/repo", external.href(FakeContext.new)
  end

  def test_an_external_tool_whose_url_resolves_to_nil_is_not_available
    external = tool(key: :sentry, route_helper: nil, url: -> { })

    assert_not external.available?(FakeContext.new)
  end

  def test_the_url_is_re_read_on_every_call
    valor = "https://first.test"
    external = tool(key: :sentry, route_helper: nil, url: -> { valor })

    assert_equal "https://first.test", external.href(FakeContext.new)
    valor = "https://second.test"
    assert_equal "https://second.test", external.href(FakeContext.new)
  end

  def test_new_tab_is_the_inverse_of_in_app
    assert_predicate tool, :new_tab?
    assert_not_predicate tool, :in_app?

    dentro = tool(in_app: true)
    assert_predicate dentro, :in_app?
    assert_not_predicate dentro, :new_tab?
  end

  def test_route_helper_and_url_together_raise
    error = assert_raises(ArgumentError) do
      Bali::Topbar::ToolsMenu::Tool.new(
        key: :x, icon: "wrench", route_helper: :some_path, url: -> { "https://example.test" }
      )
    end

    assert_includes error.message, "exclusive"
  end

  def test_neither_route_helper_nor_url_raises
    error = assert_raises(ArgumentError) do
      Bali::Topbar::ToolsMenu::Tool.new(key: :x, icon: "wrench")
    end

    assert_includes error.message, "route_helper"
  end

  # El foot-gun real: `:main_app` a secas pasa como símbolo, `available?` da `true` (el
  # contexto SÍ responde a él, porque es un proxy de engine), y `href` devolvería el
  # `RoutesProxy` mismo en vez de una URL — un enlace roto renderizado sin error. Exigir el
  # sufijo lo convierte en un `ArgumentError` al construir.
  def test_a_route_helper_that_is_not_a_path_or_url_helper_raises
    error = assert_raises(ArgumentError) do
      Bali::Topbar::ToolsMenu::Tool.new(key: :x, icon: "wrench", route_helper: :main_app)
    end

    assert_includes error.message, "_path"
  end

  # `meta` es del host: la gema lo transporta y nunca lo interpreta.
  def test_meta_round_trips_untouched
    con_meta = tool(meta: { gate: "system.admin" })

    assert_equal({ gate: "system.admin" }, con_meta.meta)
  end

  def test_meta_defaults_to_an_empty_hash
    assert_empty tool.meta
  end
end
