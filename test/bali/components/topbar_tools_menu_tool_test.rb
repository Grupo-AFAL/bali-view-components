# frozen_string_literal: true

require "test_helper"

# `Tool` answers two questions: "does this tool exist in this environment?" and "where does it
# point?". It answers the first by asking a CONTEXT IT IS GIVEN — never
# `Rails.application.routes.url_helpers`. That is why these tests use a double and mount no routes:
# it is the concrete payoff of receiving the context instead of reaching for it.
class BaliTopbarToolsMenuToolTest < ComponentTestCase
  # A pretend view context: it responds only to the helpers it is given. `main_app:` hangs a proxy
  # off it —the host's— the way Rails does inside an engine's context.
  class FakeContext
    def initialize(rutas = {}, main_app: nil)
      @rutas = rutas
      @main_app = main_app
    end

    attr_reader :main_app

    def respond_to?(name, include_all = false)
      return !@main_app.nil? if name == :main_app

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
    context = FakeContext.new({ letter_opener_web_path: "/letter_opener" })

    assert tool.available?(context)
    assert_equal "/letter_opener", tool.href(context)
  end

  def test_a_mounted_tool_is_not_available_when_the_context_does_not_know_its_helper
    assert_not tool.available?(FakeContext.new)
  end

  # An ENGINE screen's view context does not know the host's helpers, and the group's four apps serve
  # `/admin/auth/...` with the app's layout — so that is the context this menu is painted against
  # there. Without the fall back to `main_app`, migrating to this component would silently switch off
  # the mounted tools on exactly those screens. Measured in gobierno-corporativo over
  # `BaliAuth::Admin::RolesController`.
  def test_a_mounted_tool_resolves_through_main_app_in_an_engine_context
    engine = FakeContext.new(main_app: FakeContext.new({ letter_opener_web_path: "/letter_opener" }))

    assert tool.available?(engine)
    assert_equal "/letter_opener", tool.href(engine)
  end

  # The router's rule survives whole on the other side of the fall back: a helper the host does not
  # know either is still not offered. Otherwise the menu would paint a dead link on every engine
  # screen.
  def test_a_helper_the_host_does_not_know_either_is_still_unavailable
    engine = FakeContext.new(main_app: FakeContext.new({ otra_ruta_path: "/otra" }))

    assert_not tool.available?(engine)
    assert_nil tool.href(engine)
  end

  # The direct context beats the proxy: on a host screen `main_app` is not even consulted, so the
  # fall back cannot change what already resolved.
  def test_the_direct_context_wins_over_main_app
    context = FakeContext.new({ letter_opener_web_path: "/directo" },
                              main_app: FakeContext.new({ letter_opener_web_path: "/por-el-proxy" }))

    assert_equal "/directo", tool.href(context)
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

  # The real foot-gun: a bare `:main_app` passes as a symbol, `available?` says `true` (the context
  # DOES respond to it, because it is an engine proxy), and `href` would return the `RoutesProxy`
  # itself instead of a URL — a broken link rendered without an error. Requiring the suffix turns it
  # into an `ArgumentError` at construction.
  def test_a_route_helper_that_is_not_a_path_or_url_helper_raises
    error = assert_raises(ArgumentError) do
      Bali::Topbar::ToolsMenu::Tool.new(key: :x, icon: "wrench", route_helper: :main_app)
    end

    assert_includes error.message, "_path"
  end

  # `meta` belongs to the host: the gem carries it and never interprets it.
  def test_meta_round_trips_untouched
    con_meta = tool(meta: { gate: "system.admin" })

    assert_equal({ gate: "system.admin" }, con_meta.meta)
  end

  def test_meta_defaults_to_an_empty_hash
    assert_empty tool.meta
  end
end
