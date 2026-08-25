# Widgets and Widget Grid Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port enjoykitchen's user-arrangeable bento dashboard — the card, the grid, the widget contract and layout persistence — into Bali, leaving the widget classes and authorization rules in the host.

**Architecture:** One `Bali::Widget::` namespace spanning `app/lib` (value objects, `Base`, `Layout`) and `app/components` (the card). `Bali::WidgetGrid::Component` renders the bento and owns two Stimulus controllers. `Bali::Widget::Layout` is the only thing that reads or writes `bali_dashboard_widgets`, and it can only ever subset the `offering:` it was handed — so authorization never enters Bali. Bali ships no controller and no routes.

**Tech Stack:** Ruby on Rails 8.1 engine, ViewComponent 4 (`ViewComponentContrib::Base`), Stimulus, SortableJS (via `Bali::SortableList`), Tailwind v4 + daisyUI 5, Minitest + Capybara, Cypress, Lookbook.

**Spec:** `docs/superpowers/specs/2026-08-25-widgets-and-widget-grid-design.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `app/lib/bali/widget.rb` | The namespace. `SIZES`, `SEPARATOR`, `.subtitle`, `.raise_load_errors?`, `.authorized_for` |
| `app/lib/bali/widget/result.rb` | What `#call` returns |
| `app/lib/bali/widget/row.rb` | One list row |
| `app/lib/bali/widget/base.rb` | The widget contract: `sized`, `key`, i18n, `with_size`, memoized `result`, `list_from` |
| `app/lib/bali/widget/layout.rb` | Reads and writes the persisted arrangement |
| `app/models/bali/dashboard_widget.rb` | One persisted row |
| `db/migrate/20260825120000_create_bali_dashboard_widgets.rb` | The table |
| `app/components/bali/widget/component.rb` | Card: sizes, predicates, lattice classes |
| `app/components/bali/widget/component.html.erb` | Card markup incl. always-rendered edit chrome |
| `app/components/bali/widget/index.css` | Bento geometry keyed off `data-size` |
| `app/components/bali/widget/preview.rb` + `previews/` | Lookbook |
| `app/components/bali/widget_grid/component.rb` | Grid: slots, controller values |
| `app/components/bali/widget_grid/component.html.erb` | Wrapper, toolbar, announcer, SortableList, "+" tile, empty state |
| `app/components/bali/widget_grid/index.js` | `WidgetGridController` + `EditModeController` |
| `app/components/bali/widget_grid/preview.rb` + `previews/` | Lookbook |
| `cypress/e2e/widget-grid.cy.js` | Drag, arrow move, resize, remove, edit-mode URL round trip |

---

### Task 1: The namespace and its value objects

**Files:**
- Create: `app/lib/bali/widget.rb`
- Create: `app/lib/bali/widget/result.rb`
- Create: `app/lib/bali/widget/row.rb`
- Test: `test/bali/widget/result_test.rb`

This task also proves the riskiest structural assumption in the whole plan: that Zeitwerk lets `Bali::Widget` be defined by a file in `app/lib` while `app/components/bali/widget/` contributes `Component` to the same namespace. If Task 4 ever fails to load, come back here.

- [ ] **Step 1: Write the failing test**

Create `test/bali/widget/result_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliWidgetResultTest < ActiveSupport::TestCase
  def test_defaults_to_an_empty_successful_list
    result = Bali::Widget::Result.new

    assert_equal 0, result.count
    assert_empty result.items
    assert_nil result.view_all_path
    assert_nil result.payload
    refute_predicate result, :failed?
  end

  def test_failed_builds_a_failed_result
    assert_predicate Bali::Widget::Result.failed, :failed?
  end

  def test_row_defaults_subtitle_and_href_to_nil
    row = Bali::Widget::Row.new(title: "Tomatoes")

    assert_equal "Tomatoes", row.title
    assert_nil row.subtitle
    assert_nil row.href
  end

  def test_subtitle_joins_parts_and_drops_blanks
    assert_equal "3 left · Cocina", Bali::Widget.subtitle("3 left", nil, "Cocina", "")
  end

  def test_sizes_are_the_four_bento_sizes
    assert_equal %i[small medium large wide], Bali::Widget::SIZES
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/bali/widget/result_test.rb`
Expected: FAIL with `NameError: uninitialized constant Bali::Widget`

- [ ] **Step 3: Write the namespace**

Create `app/lib/bali/widget.rb`:

```ruby
# frozen_string_literal: true

module Bali
  # Dashboard widgets: the contract a host's widget classes implement, and the
  # value objects they return. `Bali::Widget::Component` renders one of them and
  # `Bali::WidgetGrid::Component` arranges many.
  #
  # This file exists so the namespace is EXPLICIT and can hold constants —
  # without it Zeitwerk would define `Bali::Widget` implicitly from the two
  # directories that extend it (`app/lib/bali/widget/` and
  # `app/components/bali/widget/`) and `SIZES` would have nowhere to live.
  module Widget
    # Semantic, not Tailwind — and 2-D, adapted from iOS: `small` is 1x1,
    # `medium` 2x1, `large` 2x2, `wide` 4x1. `large` is `medium`'s WIDTH at
    # double HEIGHT, which is why it earns more rows rather than wider ones.
    SIZES = %i[small medium large wide].freeze

    # Subtitles read "A · B" everywhere. The separator lives here rather than
    # baked into translator-editable strings.
    SEPARATOR = " · "

    class << self
      # Blank parts drop out, so a widget with only one half doesn't render a
      # dangling separator.
      def subtitle(*parts)
        parts.compact_blank.join(SEPARATOR)
      end

      # Whether a widget whose `#call` raises should take the request down with
      # it. True in development and test, so a widget bug is loud where someone
      # can fix it — this is what keeps `Base`'s rescue from being the blanket
      # kind that turns a bug into a permanent shrug. False in production, where
      # the person looking at the dashboard cannot fix it and the other tiles
      # are still worth rendering.
      #
      # A method, not a constant: `Rails.env` is read per call so a test can
      # stub this without freezing the answer at boot.
      def raise_load_errors? = Rails.env.local?

      # The gate. Un-called widget instances, so it costs only whatever the
      # host's `visible?` costs — never a widget query.
      def authorized_for(widgets)
        widgets.select(&:visible?)
      end
    end
  end
end
```

- [ ] **Step 4: Write the value objects**

Create `app/lib/bali/widget/result.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Widget
    # What every widget's `#call` returns. `Base` delegates the readers to it, so
    # `Bali::Widget::Component` talks to the widget and never sees this.
    #
    # `failed` is a field rather than a class-level declaration because a
    # declaration fifteen lines from the `#call` it describes can drift from what
    # `#call` actually returns; a field on the result cannot.
    #
    # `payload` carries pre-loaded data for a widget rendering custom content
    # through the card's `body` slot; list widgets leave it nil.
    Result = Data.define(:count, :items, :view_all_path, :payload, :failed) do
      def initialize(count: 0, items: [], view_all_path: nil, payload: nil, failed: false)
        super
      end

      # The degraded card a widget falls back to when its `#call` raises. A
      # FAILURE rather than a dropped widget on purpose: a tile that vanishes
      # reads as "nothing to see", which is the one thing a failure must not say.
      def self.failed = new(failed: true)

      def failed? = failed
    end
  end
end
```

Create `app/lib/bali/widget/row.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Widget
    # One row shape for every list widget: a title, linked when the row carries
    # an href, with a subtitle under it. Typed rather than a bare Hash because a
    # renamed key across a dozen widgets would otherwise render a blank cell
    # instead of raising.
    Row = Data.define(:title, :subtitle, :href) do
      def initialize(title:, subtitle: nil, href: nil)
        super
      end
    end
  end
end
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rails test test/bali/widget/result_test.rb`
Expected: PASS, 5 assertions-bearing tests, 0 failures

- [ ] **Step 6: Commit**

```bash
git add app/lib/bali/widget.rb app/lib/bali/widget/result.rb app/lib/bali/widget/row.rb test/bali/widget/result_test.rb
git commit -m "feat(widget): add the Bali::Widget namespace, Result and Row"
```

---

### Task 2: `Bali::Widget::Base`

**Files:**
- Create: `app/lib/bali/widget/base.rb`
- Test: `test/bali/widget/base_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/bali/widget/base_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliWidgetBaseTest < ActiveSupport::TestCase
  class LowStockItems < Bali::Widget::Base
    sized :medium

    # Overridden so the test needs no locale files; the i18n readers are covered
    # separately below.
    def self.title = "Low stock items"
    def self.short_title = "Low stock"
    def self.empty_message = "Nothing running low"

    def call
      Bali::Widget::Result.new(count: 2, view_all_path: "/items",
                               items: [Bali::Widget::Row.new(title: "Tomatoes")])
    end
  end

  class Exploding < Bali::Widget::Base
    sized :small

    def self.title = "Exploding"

    def call = raise("boom")
  end

  class Hidden < Bali::Widget::Base
    sized :small

    def self.title = "Hidden"

    def visible? = false

    def call = Bali::Widget::Result.new
  end

  def test_key_is_derived_from_the_class_name
    assert_equal "low_stock_items", LowStockItems.key
  end

  def test_sized_rejects_an_unknown_size
    error = assert_raises(ArgumentError) do
      Class.new(Bali::Widget::Base) { sized :enormous }
    end

    assert_match(/unknown widget size/, error.message)
  end

  def test_delegates_result_readers
    widget = LowStockItems.new

    assert_equal 2, widget.count
    assert_equal "/items", widget.view_all_path
    assert_equal ["Tomatoes"], widget.items.map(&:title)
    refute_predicate widget, :failed?
  end

  def test_with_size_copies_rather_than_mutating_the_class
    resized = LowStockItems.new.with_size("wide")

    assert_equal :wide, resized.size
    assert_equal :medium, LowStockItems.new.size
    assert_equal :medium, LowStockItems.size
  end

  def test_with_size_falls_back_to_the_declared_size_for_a_retired_name
    assert_equal :medium, LowStockItems.new.with_size("enormous").size
    assert_equal :medium, LowStockItems.new.with_size(nil).size
  end

  def test_a_raising_call_becomes_a_failed_result_in_production
    Bali::Widget.stub(:raise_load_errors?, false) do
      widget = Exploding.new

      assert_predicate widget, :failed?
      assert_equal 0, widget.count
    end
  end

  def test_a_raising_call_is_memoized_so_the_query_runs_once
    calls = 0
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      define_method(:call) { calls += 1; raise "boom" }
    end

    Bali::Widget.stub(:raise_load_errors?, false) do
      widget = klass.new
      widget.failed?
      widget.count
      widget.items
    end

    assert_equal 1, calls
  end

  def test_a_raising_call_still_raises_in_development_and_test
    assert_raises(RuntimeError) { Exploding.new.result }
  end

  def test_authorized_for_selects_on_visible
    widgets = [LowStockItems.new, Hidden.new]

    assert_equal [LowStockItems], Bali::Widget.authorized_for(widgets).map(&:class)
  end

  def test_i18n_readers_use_the_configured_scope
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      def self.key = "demo"
      def call = Bali::Widget::Result.new
    end

    I18n.backend.store_translations(:en, widgets: { demo: { title: "Demo widget" } })

    assert_equal "Demo widget", klass.title
    # short_title falls back to title, so a widget only needs a short one if its
    # real one doesn't fit.
    assert_equal "Demo widget", klass.short_title
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/bali/widget/base_test.rb`
Expected: FAIL with `NameError: uninitialized constant Bali::Widget::Base`

- [ ] **Step 3: Write the implementation**

Create `app/lib/bali/widget/base.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Widget
    # Shared chrome for dashboard widgets. A host subclass owns one widget: its
    # semantic `sized`, its `visible?` rule, and a `#call` returning a `Result`.
    #
    # Visibility and loading are deliberately SEPARATE halves. `visible?` costs
    # only whatever the host's predicate costs, so a picker can list every
    # authorized widget without running a single widget query; `#result` is the
    # load, and only the widgets that survive `Layout#widgets` are ever asked
    # for it.
    #
    # Bali owns the `visible?` HOOK and never the rule — roles, tenancy and
    # feature flags are things only the host can see.
    class Base
      # How many preview rows every widget loads, regardless of the size it is
      # rendered at. `count` comes from the full scope, so the preview is
      # presentation rather than data — which is what keeps `#call` from needing
      # to know a size. `Widget::Component` truncates to what the size has room
      # for.
      PREVIEW_ROWS = 8

      # No default, deliberately: a widget that forgets its size should fail
      # loudly rather than inherit one its layout was never drawn around.
      class_attribute :size

      # Widget copy is HOST content, not Bali's. Bali's own chrome lives under
      # `bali_view.widgets.*`; this is the scope a host's titles live in.
      class_attribute :i18n_scope, default: "widgets"

      class << self
        # Validated at class-definition time, so a typo is a boot failure rather
        # than a KeyError the first time someone opens the dashboard.
        def sized(name)
          raise ArgumentError, "unknown widget size #{name.inspect}" unless SIZES.include?(name)

          self.size = name
        end

        # `Widgets::LowStockItems` -> `"low_stock_items"`, which is also the
        # i18n scope and the persisted key. One fewer constant to keep in sync.
        def key
          @key ||= name.demodulize.underscore
        end

        def title = I18n.t("#{i18n_scope}.#{key}.title")

        # The `small` card is ~215px wide, where a long title wraps to three
        # lines. Falls back to the full title, so a widget only needs a short one
        # if its real one doesn't fit.
        def short_title = I18n.t("#{i18n_scope}.#{key}.short_title", default: title)

        # One line telling a picker what this widget actually shows. Several
        # titles are usually near-neighbours, so the label alone doesn't
        # distinguish them.
        def description = I18n.t("#{i18n_scope}.#{key}.description")

        # Empty-state copy, shown by the card's list body.
        def empty_message = I18n.t("#{i18n_scope}.#{key}.empty")
      end

      # `context` is whatever the host needs to gate and scope on — a Pundit
      # context, a user, a tenant, nothing at all. Bali never reads it.
      def initialize(context = nil)
        @context = context
      end

      delegate :key, :title, :short_title, :description, :empty_message, to: :class
      # The component receives the WIDGET, not its `Result`, so `widget.count` is
      # true rather than a convenient lie — and the widget still knows its own
      # key, which is what lets one component derive every widget's copy.
      delegate :count, :items, :view_all_path, :payload, :failed?, to: :result

      # Overridden by the host. Bali's default shows everything.
      def visible? = true

      # This widget rendered at a user-chosen size. Always a COPY, because `size`
      # is a `class_attribute`: assigning it on the class would resize that
      # widget for every user in the process until the next deploy. The instance
      # writer shadows the class value on this object alone.
      #
      # An unknown name falls back to the size the widget was drawn around rather
      # than raising — the name arrives from a database column, so it can
      # describe something retired between the save and the read, and a dashboard
      # that will not render is a worse answer than one drawn at its default.
      #
      # A copy even when nothing changes, so callers get one kind of thing back.
      def with_size(name)
        chosen = name&.to_sym

        dup.tap { |widget| widget.size = SIZES.include?(chosen) ? chosen : size }
      end

      def result
        @result ||= load_result
      end

      private

      attr_reader :context

      # ONE widget's failure must not take the page with it. Memoizing
      # `load_result` rather than `call` is load-bearing: the failure has to be
      # memoized too, because the component delegates `count`, `items` and
      # `view_all_path` separately and a rescue that returned without assigning
      # would re-run the raising query three times per card.
      # `NotImplementedError` is named explicitly because it descends from
      # `ScriptError`, NOT `StandardError` — so a subclass that forgets `#call`
      # would otherwise sail past this rescue and take the page down in
      # production, which is the most likely way to author a broken widget and
      # the one case the safety net has to cover. (The source app this was ported
      # from has the same latent bug.)
      def load_result
        call
      rescue StandardError, NotImplementedError => e
        raise if Widget.raise_load_errors?

        report_failure(e)
        Result.failed
      end

      # Tagged by widget key so Sentry groups these per tile rather than piling
      # every widget's failure under one controller action.
      def report_failure(error)
        Sentry.capture_exception(error, tags: { widget: failure_tag }) if defined?(Sentry)
        Rails.logger.error(
          "[bali/widget] #{failure_tag} failed to load — #{error.class}: #{error.message}\n" \
          "#{error.backtrace&.first(5)&.join("\n")}"
        )
      end

      # `key` raises for an anonymous class, which is CORRECT for `key` — it is
      # the i18n scope and the persisted `widget_key`, where a silent fallback
      # would collide. But this is the reporting path, already inside a rescue,
      # and an exception here would mask the failure it exists to record.
      def failure_tag
        key
      rescue StandardError
        self.class.name || "anonymous"
      end

      def call
        raise NotImplementedError
      end

      # The shape most list widgets share: the count is the WHOLE scope, the rows
      # are a capped preview of it, and `#row` turns each record into a `Row`.
      #
      # The scope must arrive ORDERED: paging a preview off an unordered relation
      # is a different bug in every database.
      def list_from(scope, view_all_path: nil)
        Result.new(
          count: scope.count,
          items: scope.limit(PREVIEW_ROWS).map { |record| row(record) },
          view_all_path: view_all_path
        )
      end

      def subtitle(*parts)
        Widget.subtitle(*parts)
      end

      # Reached through `helpers` rather than by including `DateHelper`: this
      # object is handed to the component, and its public surface is deliberately
      # curated by the `delegate`s above. An include would add ~17 public methods
      # to it, several of which raise outside a view.
      def time_ago_in_words(time)
        ActionController::Base.helpers.time_ago_in_words(time)
      end
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rails test test/bali/widget/base_test.rb`
Expected: PASS, 0 failures

- [ ] **Step 5: Commit**

```bash
git add app/lib/bali/widget/base.rb test/bali/widget/base_test.rb
git commit -m "feat(widget): add Bali::Widget::Base"
```

---

### Task 3: Chrome locale strings

**Files:**
- Modify: `config/locales/bali_view.en.yml`
- Modify: `config/locales/bali_view.es.yml`

The card and the grid share this vocabulary, so both use ABSOLUTE keys
(`t("bali_view.widgets.edit.remove")`) rather than relative ones. A relative
`t(".remove")` would resolve to `bali_view.widget.remove` in the card and
`bali_view.widget_grid.remove` in the grid — two copies of one string.

- [ ] **Step 1: Add the English strings**

Add under the existing `en: bali_view:` mapping in `config/locales/bali_view.en.yml`. The file is
NOT alphabetical at the top level — it is append-order by feature — so append at the end,
after `split_view:`:

```yaml
    widgets:
      load_error: "Couldn't load"
      view_all: "View all %{count}"
      empty:
        title: "No widgets yet"
        description: "Add widgets to build your dashboard."
      edit:
        edit: "Edit"
        done: "Done"
        add: "Add widget"
        hint: "Drag to rearrange, resize, or remove widgets."
        reorder: "Reorder %{widget}"
        remove: "Remove %{widget}"
        size_of: "Size of %{widget}"
        sizes:
          small: "Small"
          medium: "Medium"
          large: "Large"
          wide: "Wide"
        moved: "%{widget} moved to position %{position} of %{total}"
        removed: "%{widget} removed"
        resized: "%{widget} resized to %{size}"
        failed: "Couldn't save your changes"
        editing_on: "Editing dashboard"
        editing_off: "Done editing"
```

- [ ] **Step 2: Add the Spanish strings**

Add the mirror under `es: bali_view:` in `config/locales/bali_view.es.yml`:

```yaml
    widgets:
      load_error: "No se pudo cargar"
      view_all: "Ver todo (%{count})"
      empty:
        title: "Aún no hay widgets"
        description: "Agrega widgets para armar tu tablero."
      edit:
        edit: "Editar"
        done: "Listo"
        add: "Agregar widget"
        hint: "Arrastra para reacomodar, cambiar tamaño o quitar widgets."
        reorder: "Reacomodar %{widget}"
        remove: "Quitar %{widget}"
        size_of: "Tamaño de %{widget}"
        sizes:
          small: "Chico"
          medium: "Mediano"
          large: "Grande"
          wide: "Ancho"
        moved: "%{widget} movido a la posición %{position} de %{total}"
        removed: "%{widget} quitado"
        resized: "%{widget} cambiado a %{size}"
        failed: "No se pudieron guardar los cambios"
        editing_on: "Editando el tablero"
        editing_off: "Edición terminada"
```

- [ ] **Step 3: Verify both files parse and have the same keys**

Run:

```bash
bundle exec ruby -ryaml -e '
en = YAML.load_file("config/locales/bali_view.en.yml").dig("en","bali_view","widgets")
es = YAML.load_file("config/locales/bali_view.es.yml").dig("es","bali_view","widgets")
def flat(h, p = "") = h.flat_map { |k, v| v.is_a?(Hash) ? flat(v, "#{p}#{k}.") : ["#{p}#{k}"] }
raise "key mismatch: #{(flat(en) ^ flat(es)).inspect}" unless flat(en).sort == flat(es).sort
puts "#{flat(en).size} keys, en and es in sync"
'
```

Expected: `21 keys, en and es in sync` (4 top-level + 17 under `edit`)

- [ ] **Step 4: Commit**

```bash
git add config/locales/bali_view.en.yml config/locales/bali_view.es.yml
git commit -m "feat(widget): add widget chrome strings in en and es"
```

---

### Task 4: The card component class

**Files:**
- Create: `app/components/bali/widget/component.rb`
- Test: `test/bali/components/widget_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/bali/components/widget_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliWidgetComponentTest < ComponentTestCase
  # A real Base subclass rather than a stub, so the test exercises the contract
  # the component actually depends on. The i18n readers are overridden so this
  # file needs no locale fixtures.
  class Stock < Bali::Widget::Base
    sized :medium

    def self.title = "Low stock items"
    def self.short_title = "Low stock"
    def self.empty_message = "Nothing running low"

    class_attribute :stub_result

    def call = self.class.stub_result
  end

  def widget(size: :medium, count: 2, items: nil, view_all_path: "/items",
             payload: nil, failed: false)
    rows = items || [
      Bali::Widget::Row.new(title: "Tomatoes", subtitle: "3 left · Cocina", href: "/i/1"),
      Bali::Widget::Row.new(title: "Onions")
    ]
    Stock.stub_result = Bali::Widget::Result.new(count: count, items: rows,
                                                 view_all_path: view_all_path,
                                                 payload: payload, failed: failed)
    Stock.new.with_size(size)
  end

  def test_renders_the_card_with_its_identity_attributes
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector("section[data-widget-key='stock'][data-size='medium']")
    assert_selector("section[data-id='stock'][data-widget-title='Low stock']")
  end

  def test_medium_renders_the_title_and_three_rows
    render_inline(Bali::Widget::Component.new(widget(size: :medium, items: 5.times.map { |i|
      Bali::Widget::Row.new(title: "Row #{i}")
    })))

    assert_text("Low stock items")
    assert_selector("ul.list li", count: 3)
  end

  def test_large_renders_seven_rows
    render_inline(Bali::Widget::Component.new(widget(size: :large, items: 9.times.map { |i|
      Bali::Widget::Row.new(title: "Row #{i}")
    })))

    assert_selector("ul.list li", count: 7)
  end

  def test_small_renders_a_stat_and_no_rows
    render_inline(Bali::Widget::Component.new(widget(size: :small)))

    assert_selector("a.stat .stat-value", text: "2")
    assert_selector(".stat-title", text: "Low stock")
    assert_no_selector("ul.list")
  end

  def test_a_zero_count_small_card_dims_the_number
    render_inline(Bali::Widget::Component.new(widget(size: :small, count: 0)))

    assert_selector(".stat-value.text-base-content\\/30", text: "0")
  end

  def test_empty_list_renders_the_empty_message
    render_inline(Bali::Widget::Component.new(widget(count: 0, items: [])))

    assert_text("Nothing running low")
    assert_no_selector("ul.list")
  end

  def test_view_all_link_is_suppressed_when_there_is_nothing_to_view
    render_inline(Bali::Widget::Component.new(widget(count: 0, items: [])))

    assert_no_link(href: "/items")
  end

  def test_failed_widget_says_so_at_every_size
    %i[small medium large wide].each do |size|
      render_inline(Bali::Widget::Component.new(widget(size: size, count: 0, failed: true)))

      assert_text("Couldn't load", count: 1)
      # The confident grey zero is exactly what a failure must never render.
      assert_no_selector(".stat-value")
    end
  end

  def test_body_slot_replaces_the_list
    render_inline(Bali::Widget::Component.new(widget)) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_selector("p.verdict", text: "All clear")
    assert_no_selector("ul.list")
  end

  def test_body_slot_still_yields_to_the_summary_at_small
    render_inline(Bali::Widget::Component.new(widget(size: :small))) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_no_selector("p.verdict")
    assert_selector(".stat-value", text: "2")
  end

  def test_renders_a_size_button_per_size_with_the_current_one_pressed
    render_inline(Bali::Widget::Component.new(widget(size: :wide)))

    assert_selector("button[data-widget-size]", count: 4, visible: :all)
    assert_selector("button[data-widget-size='wide'][aria-pressed='true']", visible: :all)
    assert_selector("button[data-widget-size='small'][aria-pressed='false']", visible: :all)
  end

  def test_edit_chrome_is_always_rendered_so_entering_edit_mode_costs_no_round_trip
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector("button.handle[data-action='keydown->bali-widget-grid#move']", visible: :all)
    assert_selector("button[data-action='bali-widget-grid#remove']", visible: :all)
  end

  def test_cell_class_marks_the_filled_cells_of_each_size
    component = Bali::Widget::Component.new(widget)

    assert_includes component.cell_class(:large, 5), "bg-base-content/45"
    assert_includes component.cell_class(:large, 2), "bg-base-content/20"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/bali/components/widget_test.rb`
Expected: FAIL with `NameError: uninitialized constant Bali::Widget::Component`

- [ ] **Step 3: Write the component class**

Create `app/components/bali/widget/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Widget
    # The single entry point for rendering any dashboard widget:
    #
    #   render Bali::Widget::Component.new(widget)
    #
    # Takes the WIDGET, not its `Result` — the widget delegates count/items to
    # the result and still knows its own key, which is what lets one component
    # derive every widget's copy.
    #
    # Does no data access at all, which is what lets it be tested against plain
    # `Base` subclasses with a stubbed `#call`.
    class Component < ApplicationViewComponent
      # How many of the widget's `PREVIEW_ROWS` this card has room for.
      # Truncation lives HERE, not in `#call`: the widget answers "which rows
      # matter", the card answers "how many fit".
      #
      # `small` renders NO rows on purpose — a ~215px card with three truncated
      # titles is worse than the single number those rows summarise, so it shows
      # a stat instead. That is what "the design changes with the size" means.
      ROWS = { small: 0, medium: 3, large: 7, wide: 3 }.freeze

      # Which of the 4x2 lattice cells each size fills, in the grid's own reading
      # order: left to right, top row then bottom.
      #
      # The LATTICE is the point, not the fill. Four rectangles floating in
      # whitespace are four masses with no shared origin — which is why `medium`
      # (2x1) and `large` (2x2), being the same WIDTH, were indistinguishable.
      # The same four inside a visible 4x2 grid are a map.
      CELLS = {
        small: [0],
        medium: [0, 1],
        large: [0, 1, 4, 5],
        wide: [0, 1, 2, 3]
      }.freeze

      # The empty cell is a CONSTANT — `base-content`, never `current` — because
      # a frame of reference that changes with the state it frames is not a
      # reference. Deriving it from the button's text colour stacked two
      # opacities into 9% ink on white: invisible, which collapsed the map back
      # into the mass it replaced.
      CELL_FILLED = "rounded-[1px] bg-base-content/45 " \
                    "group-hover:bg-base-content/70 group-aria-pressed:bg-primary"
      CELL_EMPTY = "rounded-[1px] bg-base-content/20 group-aria-pressed:bg-primary/25"

      # Custom content for a widget that isn't a list. Replaces the shape enum
      # enjoykitchen used, which had to name an app concept (`:verdict`) inside
      # a library.
      renders_one :body

      delegate :key, :title, :short_title, :count, :items, :view_all_path,
               :empty_message, :size, :failed?, to: :widget

      def initialize(widget)
        @widget = widget
        super()
      end

      def rows = items.first(ROWS.fetch(size))

      # The compact card: a count, a short label, and the whole tile is the link.
      def summary? = ROWS.fetch(size).zero?

      def any_items? = count.positive?

      def view_all_link? = any_items? && view_all_path.present?

      # Here rather than in the template so the template stops doing conditional
      # presentation with fully qualified constants on a 160-character line.
      def cell_class(name, cell)
        CELLS.fetch(name).include?(cell) ? CELL_FILLED : CELL_EMPTY
      end

      private

      attr_reader :widget
    end
  end
end
```

- [ ] **Step 4: Run test to verify it fails on the missing template**

Run: `bundle exec rails test test/bali/components/widget_test.rb`
Expected: FAIL with a missing-template error — the class exists, the ERB does not. Task 5 writes it.

- [ ] **Step 5: Commit**

```bash
git add app/components/bali/widget/component.rb test/bali/components/widget_test.rb
git commit -m "feat(widget): add the card component class"
```

---

### Task 5: The card template and bento CSS

**Files:**
- Create: `app/components/bali/widget/component.html.erb`
- Create: `app/components/bali/widget/index.css`
- Modify: `app/assets/stylesheets/bali/components.css`
- Test: `test/bali/components/widget_test.rb` (already written in Task 4)

- [ ] **Step 1: Write the template**

Create `app/components/bali/widget/component.html.erb`:

```erb
<%# One card for every widget. The chrome — box, heading, optional "view all" —
    is the same for all of them; the BODY is what changes, and `size` selects how
    much of it there is.

    A `small` card is a different card, not a narrower one: it drops the heading
    row and the list for a single daisyUI `stat`, and the whole tile becomes the
    link.

    The edit chrome is rendered ALWAYS and hidden by CSS, never toggled by the
    server: entering edit mode is a class on the grid wrapper, so it costs no
    round trip and re-runs none of the widget queries. `[.editing_&]:` is
    Tailwind's arbitrary-parent variant — "when an ancestor has `.editing`".

    `data-id` is what SortableJS's `toArray` reads and `data-widget-key` is what
    the grid controller reads. Same value, different consumers; collapsing them
    would couple the payload to SortableJS's internals. %>
<section data-id="<%= key %>"
         data-widget-key="<%= key %>"
         data-widget-title="<%= short_title %>"
         data-size="<%= size %>"
         class="relative flex h-full flex-col rounded-box border border-base-300 bg-base-100 <%= summary? ? 'p-4' : 'p-6' %> [.editing_&]:border-dashed [.editing_&]:border-primary [.editing_&]:shadow-lg">
  <%# No jiggle. A wobbling card of overdue counts reads as a rendering fault
      rather than an affordance, makes the text unreadable, and collides with
      `prefers-reduced-motion`. Raised + dashed accent + a dimmed inert body is
      the web's vocabulary for "manipulable object".

      INSIDE the card, not hanging into the gutter: a band at `-top-3` in a 16px
      gap puts one card's ✕ under a neighbour's centre in a mixed bento, and
      paint order decides which one you can click. %>
  <div class="hidden [.editing_&]:absolute [.editing_&]:inset-x-0 [.editing_&]:top-2 [.editing_&]:z-10 [.editing_&]:flex [.editing_&]:items-center [.editing_&]:justify-between [.editing_&]:px-3">
    <%# A real <button>, so it takes focus and arrows can move the card. This is
        the whole keyboard path: SortableJS is pointer-only, and Bali's own
        keyboard reordering only acts on focused `.sortable-item` children, which
        these cards deliberately are not. %>
    <button type="button"
            class="handle btn btn-circle btn-xs btn-ghost bg-base-100 shadow"
            aria-label="<%= t('bali_view.widgets.edit.reorder', widget: short_title) %>"
            data-action="keydown->bali-widget-grid#move">
      <%= render Bali::Icon::Component.new('handle', size: :small) %>
    </button>

    <%# Top-right, not the top-left minus, which means nothing on the web — and
        "view all" is suppressed in edit mode anyway, so the slot is free. %>
    <button type="button"
            class="btn btn-circle btn-xs btn-error"
            aria-label="<%= t('bali_view.widgets.edit.remove', widget: short_title) %>"
            data-action="bali-widget-grid#remove">
      <%= render Bali::Icon::Component.new('x', size: :small) %>
    </button>
  </div>

  <%# A shelf, not a floating pill. In edit mode the body is `inert` at 50%
      opacity, so this is chrome sitting on switched-off content — the move a
      video player's control bar makes.

      `bg-base-200` is the PAGE's material, not the card's: `bg-base-100/95` is
      the same white as the card it sits in, so it read as more card.

      Hidden below `lg`, where all four sizes render identically and the control
      would visibly do nothing.

      The names live in `title` and `aria-label`: four labels of four different
      lengths will not fit, but a hover should still say what you are choosing. %>
  <div class="hidden [.editing_&]:absolute [.editing_&]:inset-x-0 [.editing_&]:bottom-0 [.editing_&]:z-10 [.editing_&]:h-12 [.editing_&]:items-center [.editing_&]:justify-center [.editing_&]:rounded-b-box [.editing_&]:border-t [.editing_&]:border-base-300 [.editing_&]:bg-base-200 [.editing_&]:px-1 [.editing_&]:max-lg:hidden [.editing_&]:lg:flex">
    <div class="join" role="group"
         aria-label="<%= t('bali_view.widgets.edit.size_of', widget: short_title) %>">
      <% Bali::Widget::SIZES.each do |name| %>
        <%# Height and padding are separate dials and only one was the problem:
            `btn-xs` shrinks both, overriding `--btn-p` takes the dead space and
            leaves the click target alone.

            Selection is `aria-pressed` and NOTHING else — the cell variants read
            it, so the controller sets one attribute and every visual consequence
            follows. No class for the server and the client to disagree about. %>
        <button type="button"
                class="group join-item btn btn-sm [--btn-p:.375rem] border-base-300 bg-base-100 hover:border-base-content/25 aria-pressed:border-primary/40 aria-pressed:bg-primary/10"
                aria-pressed="<%= name == size %>"
                aria-label="<%= t("bali_view.widgets.edit.sizes.#{name}") %>"
                title="<%= t("bali_view.widgets.edit.sizes.#{name}") %>"
                data-widget-size="<%= name %>"
                data-action="bali-widget-grid#resize">
          <span class="grid h-3.5 w-6 grid-cols-4 grid-rows-2 gap-px" aria-hidden="true">
            <% 8.times do |cell| %>
              <span class="<%= cell_class(name, cell) %>"></span>
            <% end %>
          </span>
        </button>
      <% end %>
    </div>
  </div>

  <%# Genuinely `inert` while editing, set by `edit-mode` — not merely
      `pointer-events-none`, which stops the mouse and leaves every link in the
      tab order. Tabbing into a 50%-opacity card and pressing Enter would
      navigate away mid-arrangement, which is the exact failure this prevents.
      `inert` cannot be expressed as a CSS class, which is why this one piece of
      edit state is applied in JS. %>
  <div data-edit-mode-target="inert"
       class="flex min-h-0 flex-1 flex-col [.editing_&]:opacity-50 [.editing_&]:lg:pb-12">
    <%# BEFORE the size split, so a widget that couldn't load says so at every
        size. It carries its own `short_title` because the heading row belongs to
        the non-summary branch, and a bare "couldn't load" in a bento of twelve
        cards doesn't say WHICH one failed.

        `text-warning`, not the `/40` grey the empty state uses: those are
        opposite messages and the muted one already means "nothing to do". No
        retry link — the reload is the retry, and a button that re-runs the same
        broken query promises a recovery this card cannot make. %>
    <% if failed? %>
      <div class="flex flex-1 flex-col items-center justify-center gap-1 px-2 text-center">
        <p class="text-sm font-medium text-base-content/70"><%= short_title %></p>
        <p class="text-xs text-warning"><%= t('bali_view.widgets.load_error') %></p>
      </div>
    <% elsif summary? %>
      <%= link_to view_all_path || '#', class: 'stat flex-1 place-content-center p-0' do %>
        <div class="stat-value text-4xl tabular-nums <%= count.positive? ? 'text-base-content' : 'text-base-content/30' %>">
          <%= count %>
        </div>
        <div class="stat-title mt-1 whitespace-normal text-sm leading-tight"><%= short_title %></div>
      <% end %>
    <% else %>
      <%= render Bali::PageHeader::Component.new do |c| %>
        <% c.with_title(title, tag: :h5) %>

        <%# `Bali::Link` rather than a bare `link_to`: its base class is already
            `link inline-flex items-center gap-1` and `icon_right` puts the
            chevron after the label. %>
        <% if view_all_link? %>
          <%= render Bali::Link::Component.new(
                name: t('bali_view.widgets.view_all', count: count),
                href: view_all_path,
                class: 'text-sm text-base-content/60 hover:text-primary no-underline') do |c| %>
            <% c.with_icon_right('chevron-right', class: 'w-3 h-3') %>
          <% end %>
        <% end %>
      <% end %>

      <% if body? %>
        <div class="min-h-0 flex-1 overflow-hidden"><%= body %></div>
      <% elsif any_items? %>
        <%# `rows`, not `items`: widgets load `PREVIEW_ROWS` regardless of size
            and the card truncates to what it has room for. The rows are plain
            value objects, so this branch never touches a model. %>
        <ul class="list min-h-0 flex-1 overflow-hidden">
          <% rows.each do |row| %>
            <li class="list-row px-0">
              <div class="list-col-grow min-w-0">
                <% if row.href %>
                  <%= link_to row.title, row.href,
                        class: 'font-medium text-base-content hover:text-primary transition-colors block truncate' %>
                <% else %>
                  <p class="font-medium text-base-content truncate"><%= row.title %></p>
                <% end %>
                <% if row.subtitle.present? %>
                  <p class="text-xs text-base-content/60 mt-0.5 truncate"><%= row.subtitle %></p>
                <% end %>
              </div>
            </li>
          <% end %>
        </ul>
      <% else %>
        <p class="flex-1 place-content-center text-center text-sm text-base-content/40">
          <%= empty_message %>
        </p>
      <% end %>
    <% end %>
  </div>
</section>
```

- [ ] **Step 2: Write the bento CSS**

Create `app/components/bali/widget/index.css`:

```css
/* Bento geometry for the widget grid.
 *
 * A card declares WHAT it is — `data-size="large"` — and this stylesheet decides
 * what that means at each breakpoint. The alternative (the card carrying the
 * Tailwind spans, all four sizes serialised as JSON so the client can swap, and
 * the controller doing class arithmetic) is three copies of one fact in three
 * languages.
 *
 * It also retires the reason that existed: Tailwind only sees class names it can
 * read as literals in the files it scans, so `col-span-${n}` built in JS reaches
 * no stylesheet. None of that matters when the client writes an ATTRIBUTE.
 *
 * 2-D sizes, adapted from iOS: small 1x1, medium 2x1, large 2x2, wide 4x1.
 * `large` is `medium`'s WIDTH at double HEIGHT, which is why it earns more rows
 * rather than wider ones.
 *
 * A CHILD combinator, not a descendant one: `data-size` is a generic attribute
 * name and the grid contains third-party markup. `>` costs nothing and
 * forecloses a bug that would be baffling.
 *
 * Breakpoints match Tailwind's `md` (48rem) and `lg` (64rem) because the grid
 * container declares its column count in Tailwind utilities. Below `md`
 * everything is one column, so no size means anything and no rule applies.
 *
 * Imported into `@layer components`: these rules only set grid placement and
 * nothing here needs to outrank daisyUI. Being in `components` is what lets a
 * host override a span with `lg:col-span-4` and no `!` variant.
 */

@media (width >= 48rem) {
  /* Two columns: everything except `small` fills the row. */
  .bali-widget-grid > [data-size="medium"],
  .bali-widget-grid > [data-size="large"],
  .bali-widget-grid > [data-size="wide"] {
    grid-column: span 2 / span 2;
  }
}

@media (width >= 64rem) {
  .bali-widget-grid > [data-size="small"] {
    grid-column: span 1 / span 1;
  }

  .bali-widget-grid > [data-size="medium"] {
    grid-column: span 2 / span 2;
  }

  .bali-widget-grid > [data-size="large"] {
    grid-column: span 2 / span 2;
    grid-row: span 2 / span 2;
  }

  .bali-widget-grid > [data-size="wide"] {
    grid-column: span 4 / span 4;
  }
}
```

- [ ] **Step 3: Import the stylesheet**

Add to `app/assets/stylesheets/bali/components.css`, next to the other layered component imports (after the `gantt` line):

```css
@import "../../../components/bali/widget/index.css" layer(components);
```

- [ ] **Step 4: Run the card tests**

Run: `bundle exec rails test test/bali/components/widget_test.rb`
Expected: PASS, 0 failures

- [ ] **Step 5: Rebuild CSS and confirm the bento rules landed**

Run:

```bash
bundle exec rails app:tailwindcss:build
grep -c "bali-widget-grid" spec/dummy/app/assets/builds/tailwind.css
```

Expected: a non-zero count (the four `data-size` rules)

- [ ] **Step 6: Commit**

```bash
git add app/components/bali/widget/component.html.erb app/components/bali/widget/index.css app/assets/stylesheets/bali/components.css
git commit -m "feat(widget): add the card template and bento geometry"
```

---

### Task 6: Card Lookbook preview

**Files:**
- Create: `app/components/bali/widget/preview.rb`
- Create: `app/components/bali/widget/previews/default.html.erb`

Per `.claude/CLAUDE.md`: previews inherit `ApplicationViewComponentPreview`, and a
preview file must name sibling constants IN FULL (`Bali::Widget::SIZES`, never
`SIZES`) — `Module.nesting` is captured at parse time and Lookbook keeps the class
in its own registry, so a later `reload!` leaves short forms resolving against a
namespace Zeitwerk has discarded.

- [ ] **Step 1: Write the preview**

Create `app/components/bali/widget/preview.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Widget
    class Preview < ApplicationViewComponentPreview
      # A widget with no host behind it. Defined here so the preview needs no
      # dummy-app model and no locale fixtures.
      class Demo < Bali::Widget::Base
        sized :medium

        def self.title = "Low stock items"
        def self.short_title = "Low stock"
        def self.empty_message = "Nothing running low"

        def initialize(count:, failed:)
          @count = count
          @failed = failed
          super(nil)
        end

        def call
          return Bali::Widget::Result.failed if @failed

          Bali::Widget::Result.new(
            count: @count,
            view_all_path: "/lookbook",
            items: Array.new(@count) do |i|
              Bali::Widget::Row.new(title: "Ingredient #{i + 1}",
                                    subtitle: Bali::Widget.subtitle("#{i + 1} left", "Cocina"),
                                    href: "/lookbook")
            end
          )
        end
      end

      # A dashboard card. `size` changes the design, not just the width: `small`
      # drops the list for a single stat, and `large` is `medium`'s width at
      # double height.
      #
      # Toggle `editing` to see the edit chrome — a handle, a remove button and
      # the size picker — which the card always renders and CSS hides.
      #
      # @param size select { choices: [small, medium, large, wide] }
      # @param count number
      # @param failed toggle
      # @param editing toggle
      def default(size: :medium, count: 5, failed: false, editing: false)
        render_with_template(locals: {
                               widget: Demo.new(count: count.to_i, failed: failed)
                                           .with_size(size),
                               editing: editing
                             })
      end
    end
  end
end
```

- [ ] **Step 2: Write the preview template**

Create `app/components/bali/widget/previews/default.html.erb`:

```erb
<%# The `.editing` class normally lives on the grid wrapper that `edit-mode`
    toggles; here it is hard-coded so a single card can be inspected in both
    states. `lg:h-64` matches the grid's `auto-rows-[16rem]` so the card has the
    height its layout was drawn around. %>
<div class="<%= 'editing' if editing %> max-w-md p-8">
  <div class="lg:h-64">
    <%= render Bali::Widget::Component.new(widget) %>
  </div>
</div>
```

- [ ] **Step 3: Verify the preview renders**

Run:

```bash
cd spec/dummy && bin/dev
```

Then open `http://localhost:3001/lookbook/preview/bali/widget/default` and step
through all four sizes plus `editing` and `failed`. Confirm: `small` shows a stat
and no rows; `large` shows seven; `editing` reveals the handle, the ✕ and the size
picker with the current size pressed; `failed` shows the warning at every size.

Expected: no 500s, all six param combinations render.

- [ ] **Step 4: Commit**

```bash
git add app/components/bali/widget/preview.rb app/components/bali/widget/previews/default.html.erb
git commit -m "feat(widget): add the card Lookbook preview"
```

---

### Task 7: The Stimulus controllers

**Files:**
- Create: `app/components/bali/widget_grid/index.js`
- Modify: `app/frontend/bali/components/index.js`
- Modify: `app/frontend/bali/index.js`

Two controllers in one file, composed on one element. They share no state:
nothing in `edit-mode` reads a card, and nothing that moves a card reads
`editing`.

- [ ] **Step 1: Write the controllers**

Create `app/components/bali/widget_grid/index.js`:

```javascript
import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'

// Turns grid gestures into a persisted layout: drag or arrow keys to reorder,
// the remove button to drop a card, a glyph to resize.
//
// Every gesture is the SAME operation as far as the server is concerned: each
// sends the whole layout — which widgets, in what order, at what size — and they
// differ only in what they do to the DOM first. One endpoint, one write path,
// one queue.
//
// Entering edit mode is `EditModeController`'s job; the two are composed on one
// element and share no state.
export class WidgetGridController extends Controller {
  static targets = ['grid', 'announcer']
  static values = {
    url: String,
    movedText: String,
    removedText: String,
    failedText: String,
    resizedText: String
  }

  // A queued write belongs to a grid that no longer exists: without this, a
  // Turbo navigation during the debounce window fires a PATCH describing a DOM
  // that has already been replaced.
  disconnect () {
    clearTimeout(this.timer)
  }

  // Fired by Bali's sortable-list controller after a drop. Its per-item PATCH is
  // deliberately not wired up (the cards carry no `data-sortable-update-url`):
  // it posts 1-based positions for one item where we write a 0-based whole
  // sequence. The whole sequence is one write.
  reordered () {
    this.persist()
  }

  remove (event) {
    const card = event.target.closest('[data-widget-key]')
    if (!card) return

    const label = card.dataset.widgetTitle
    // Focus has to be placed BEFORE the card leaves, or it falls to `<body>` and
    // a keyboard user loses their place in a twelve-card grid. Deleting is the
    // gesture where losing your place costs most.
    const cards = this.cards
    const next = cards[cards.indexOf(card) + 1] ?? cards[cards.indexOf(card) - 1]

    card.remove()
    this.focusHandle(next)
    this.announce(this.removedTextValue.replace('%{widget}', label))
    this.persist()
  }

  // The size is swapped locally first so the card resizes under the cursor. The
  // server is being told, not asked — and told the same thing every other
  // gesture tells it, since the card carries its size into the payload.
  resize (event) {
    const button = event.target.closest('[data-widget-size]')
    const card = button?.closest('[data-widget-key]')
    if (!card) return

    const size = button.dataset.widgetSize
    if (size === this.currentSize(card)) return

    this.applySize(card, size)
    this.announce(
      this.resizedTextValue
        .replace('%{widget}', card.dataset.widgetTitle)
        .replace('%{size}', button.getAttribute('aria-label'))
    )

    this.persist()
  }

  currentSize (card) {
    return card.querySelector('[data-widget-size][aria-pressed="true"]')?.dataset.widgetSize
  }

  // ONE attribute for the geometry: the stylesheet owns what each size MEANS at
  // each breakpoint, so nothing here builds a class name — which is also why it
  // no longer matters that Tailwind cannot see class names built at runtime.
  //
  // And ONE attribute for the selection: every visual consequence is expressed
  // by `aria-pressed:` and `group-aria-pressed:` variants in the card template,
  // so there is no class list for the server and the client to disagree about,
  // and the accessible state and the visible state cannot drift.
  applySize (card, size) {
    card.dataset.size = size

    card.querySelectorAll('[data-widget-size]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.widgetSize === size))
    })
  }

  // No fallback when there is no card left: the grid is empty, which means the
  // sequence just sent was empty, which means `writeSequence` is about to reload
  // for the restored defaults.
  focusHandle (card) {
    card?.querySelector('.handle')?.focus()
  }

  // Bali's SortableList grew keyboard reordering, but it only acts on focused
  // `:scope > .sortable-item` children — which these cards deliberately are not,
  // because `SortableList::Item::Component` carries list-row styling that fights
  // the bento. So this is the entire keyboard path, and it handles Left/Right
  // too: meaningless in a list, essential in a four-column bento.
  move (event) {
    const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[event.key]
    if (!step) return

    const card = event.target.closest('[data-widget-key]')
    const cards = this.cards
    const from = cards.indexOf(card)
    const to = from + step
    if (from === -1 || to < 0 || to >= cards.length) return

    event.preventDefault()
    if (step > 0) cards[to].after(card)
    else cards[to].before(card)

    // Focus follows the card, not the index — the DOM move blurs the button.
    this.focusHandle(card)
    this.announce(
      this.movedTextValue
        .replace('%{widget}', card.dataset.widgetTitle)
        .replace('%{position}', to + 1)
        .replace('%{total}', cards.length)
    )
    this.persist()
  }

  get cards () {
    return Array.from(this.gridTarget.querySelectorAll('[data-widget-key]'))
  }

  announce (message) {
    if (this.hasAnnouncerTarget && message) this.announcerTarget.textContent = message
  }

  // Debounced AND serialized, for two different failures.
  //
  // Debounced because arrow keys auto-repeat: holding one fires a gesture every
  // few milliseconds, and each would otherwise be a full PATCH. The trailing
  // edge collapses a held key into the one write that describes where the card
  // came to rest.
  //
  // Serialized because every gesture sends a full snapshot, so two in-flight
  // requests are two complete and DIFFERENT answers to "what is the
  // arrangement", and nothing about HTTP guarantees the later one commits last.
  // Drag a card, immediately remove another, and the stale snapshot can win —
  // resurrecting the widget you just deleted.
  //
  // The snapshot is read when the request is BUILT, not when it is queued, so a
  // queued write still sends the latest DOM.
  persist () {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.enqueue(() => this.writeSequence()), 250)
  }

  enqueue (write) {
    this.queue = Promise.resolve(this.queue).then(write)
    return this.queue
  }

  // The whole layout, read out of the DOM: order from the card order, size from
  // whichever glyph is pressed. Submitting the order on a resize is not an
  // overreach — this IS the order, and the server has no better source for it.
  async writeSequence () {
    const body = new FormData()
    this.cards.forEach(card => {
      body.append('widgets[][key]', card.dataset.widgetKey)
      body.append('widgets[][size]', this.currentSize(card) ?? '')
    })

    if (!await this.send(this.urlValue, body)) return

    // Removing the LAST widget sends an empty sequence, and no rows means "never
    // chose" — so the server answers by restoring every authorized widget. The
    // `204` contract means nothing comes back to render, which would leave an
    // empty grid on screen over a full dashboard in the database, wrong until
    // the next reload. This is the one gesture that has to go back for markup.
    if (this.cards.length === 0) this.reload()
  }

  // Failures are announced, never swallowed. The whole design rests on the DOM
  // being truthful — no draft, no save button — so the one moment it stops being
  // truthful is the one moment the user has to be told.
  async send (url, body) {
    try {
      const response = await patch(url, { body, responseKind: 'json' })
      if (!response.ok) this.announce(this.failedTextValue)

      return response.ok
    } catch {
      this.announce(this.failedTextValue)

      return false
    }
  }

  // Its own method so a test can observe and stub it.
  reload () {
    window.location.reload()
  }
}

// Puts a page into an edit mode and remembers it in the URL. Knows nothing about
// widgets — it toggles a class, swaps the control that enters for the one that
// leaves, marks a subtree `inert`, and announces the change.
//
// Compose them on one element:
//
//   <div data-controller="bali-widget-grid edit-mode" ...>
//
export class EditModeController extends Controller {
  static targets = ['enter', 'leave', 'inert', 'announcer']
  static classes = ['editing']
  static values = {
    editing: { type: Boolean, default: false },
    onText: String,
    offText: String
  }

  connect () {
    // Back leaves edit mode rather than the page, and a restore visit has to
    // re-enter it — so the flag lives in the URL, not only in memory.
    this.editingValue = this.editingInUrl
    this.popstate = () => { this.editingValue = this.editingInUrl }
    window.addEventListener('popstate', this.popstate)
  }

  disconnect () {
    window.removeEventListener('popstate', this.popstate)
  }

  get editingInUrl () {
    return new URLSearchParams(window.location.search).has('editing')
  }

  // The controls are real links to real URLs, so the default action is a correct
  // — just wasteful — full page load. Cancelling it turns the same navigation
  // into a class flip, and the page still works if this controller never loads.
  enter (event) {
    event?.preventDefault()
    this.push(true)
    this.editingValue = true
  }

  leave (event) {
    event?.preventDefault()
    this.push(false)
    this.editingValue = false
  }

  // Ignored while idle so it doesn't swallow Escape from a modal or a dropdown.
  keydown (event) {
    if (event.key === 'Escape' && this.editingValue) this.leave()
  }

  editingValueChanged (editing, wasEditing) {
    this.element.classList.toggle(this.editingClass, editing)
    // Enter and leave occupy the same slot: the control you press to leave
    // should be where the one you pressed to enter was.
    if (this.hasEnterTarget) this.enterTarget.hidden = editing
    if (this.hasLeaveTarget) this.leaveTarget.hidden = !editing
    // The one piece of edit state CSS cannot express: `pointer-events-none`
    // stops the mouse and leaves every link in the tab order.
    this.inertTargets.forEach(target => { target.inert = editing })

    // A sighted user sees the page change. Without this, a screen-reader user
    // gets silence and finds the mode by stumbling into new buttons. Skipped on
    // the initial set, which is a render rather than a transition.
    if (wasEditing === undefined) return
    this.announce(editing ? this.onTextValue : this.offTextValue)
  }

  push (editing) {
    const url = new URL(window.location.href)
    if (editing) url.searchParams.set('editing', '1')
    else url.searchParams.delete('editing')
    window.history.pushState({}, '', url)
  }

  announce (message) {
    if (this.hasAnnouncerTarget && message) this.announcerTarget.textContent = message
  }
}
```

- [ ] **Step 2: Register both controllers in the components bundle**

In `app/frontend/bali/components/index.js` make three edits.

Add the import next to the `KanbanController` import:

```javascript
import { WidgetGridController, EditModeController } from '../../../components/bali/widget_grid/index'
```

Add both names to the alphabetical named-export block (`EditModeController` goes
between `DropdownController` and `ExportLinksController`; `WidgetGridController`
goes at the end of the list):

```javascript
  EditModeController,
```
```javascript
  WidgetGridController,
```

Add both identifiers to the `CONTROLLERS` map, in the `// Interactive` group next
to `kanban`:

```javascript
  'bali-widget-grid': WidgetGridController,
  'edit-mode': EditModeController,
```

- [ ] **Step 3: Re-export from the package root**

In `app/frontend/bali/index.js`, add both names to the components re-export block
(the `export { … }` starting around line 85), keeping alphabetical order:

```javascript
  EditModeController,
```
```javascript
  WidgetGridController,
```

- [ ] **Step 4: Verify the manifest check passes**

Run: `yarn check:manifest`
Expected: exit 0, no "unreachable controller" or "not re-exported" errors

- [ ] **Step 5: Verify lint passes**

Run: `npx eslint app/components/bali/widget_grid/index.js`
Expected: no output (clean)

- [ ] **Step 6: Commit**

```bash
git add app/components/bali/widget_grid/index.js app/frontend/bali/components/index.js app/frontend/bali/index.js
git commit -m "feat(widget-grid): add the grid and edit-mode Stimulus controllers"
```

---

### Task 8: The grid component

**Files:**
- Create: `app/components/bali/widget_grid/component.rb`
- Create: `app/components/bali/widget_grid/component.html.erb`
- Test: `test/bali/components/widget_grid_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/bali/components/widget_grid_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliWidgetGridComponentTest < ComponentTestCase
  class Stock < Bali::Widget::Base
    sized :medium

    def self.title = "Low stock items"
    def self.short_title = "Low stock"
    def self.empty_message = "Nothing running low"

    def call
      Bali::Widget::Result.new(count: 1, view_all_path: "/items",
                               items: [Bali::Widget::Row.new(title: "Tomatoes")])
    end
  end

  def test_renders_the_two_composed_controllers_and_the_endpoint
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout"))

    assert_selector("[data-controller='bali-widget-grid edit-mode']", visible: :all)
    assert_selector("[data-bali-widget-grid-url-value='/widget_layout']", visible: :all)
  end

  def test_renders_one_card_per_widget_inside_the_sortable_grid
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout")) do |grid|
      grid.with_widget(Stock.new)
      grid.with_widget(Stock.new.with_size(:small))
    end

    assert_selector(".bali-widget-grid[data-controller~='sortable-list']", visible: :all)
    assert_selector(".bali-widget-grid > section[data-widget-key='stock']", count: 2, visible: :all)
  end

  def test_the_grid_listens_for_bali_s_own_sortable_event
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector(
      ".bali-widget-grid[data-action*='bali:sortable-list:end->bali-widget-grid#reordered']",
      visible: :all
    )
  end

  def test_a_widget_can_replace_its_body
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout")) do |grid|
      grid.with_widget(Stock.new) do |card|
        card.with_body { "<p class='verdict'>All clear</p>".html_safe }
      end
    end

    assert_selector("p.verdict", text: "All clear")
  end

  def test_renders_the_add_tile_only_when_a_path_is_given
    render_inline(Bali::WidgetGrid::Component.new(url: "/l", add_path: "/widgets/edit")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector("a[href='/widgets/edit'][data-size='small']", visible: :all)
  end

  def test_omits_the_add_tile_when_no_path_is_given
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_no_selector("a[data-size='small']", visible: :all)
  end

  def test_renders_an_empty_state_when_there_are_no_widgets
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector(".empty-state-component")
    assert_no_selector(".bali-widget-grid")
  end

  def test_the_default_toolbar_offers_enter_and_a_hidden_leave
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector("[data-edit-mode-target='enter'] button[data-action='edit-mode#enter']", visible: :all)
    assert_selector("[data-edit-mode-target='leave'][hidden] button[data-action='edit-mode#leave']", visible: :all)
  end

  def test_a_custom_toolbar_replaces_the_default
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
      grid.with_toolbar { "<h1>My dashboard</h1>".html_safe }
    end

    assert_selector("h1", text: "My dashboard")
    assert_no_selector("[data-edit-mode-target='enter']", visible: :all)
  end

  def test_renders_one_announcer_shared_by_both_controllers
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector(
      "[role='status'][aria-live='polite'][data-bali-widget-grid-target='announcer'][data-edit-mode-target='announcer']",
      visible: :all
    )
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/bali/components/widget_grid_test.rb`
Expected: FAIL with `NameError: uninitialized constant Bali::WidgetGrid`

- [ ] **Step 3: Write the component class**

Create `app/components/bali/widget_grid/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module WidgetGrid
    # The bento: a grid of `Bali::Widget::Component` cards a user can rearrange,
    # resize and remove, with the whole layout persisted on every gesture.
    #
    #   render Bali::WidgetGrid::Component.new(url: widget_layout_path) do |grid|
    #     widgets.each { |widget| grid.with_widget(widget) }
    #   end
    #
    # `url` is a host endpoint. Bali ships no controller and no routes: who may
    # see which widget is the host's rule, and the write goes through
    # `Bali::Widget::Layout`.
    class Component < ApplicationViewComponent
      # A string rather than the constant, so this class carries no load-order
      # dependency on the card.
      renders_many :widgets, "Bali::Widget::Component"

      # Defaults to enter/leave controls in one slot. A host that wants a heading
      # and its own buttons replaces the whole band.
      renders_one :toolbar

      renders_one :empty_state

      # Fixed row height, not `stretch`: sizes are 2-D boxes, so `large` means
      # "two rows tall", which is meaningless while rows size to content.
      #
      # `md:grid-cols-2` exists because this used to jump 1 -> 4 columns at `lg`,
      # so a tablet in portrait got a single column and none of the size system.
      #
      # Deliberately NOT `grid-flow-dense`: it backfills gaps by pulling later
      # tiles forward, which would silently overrule the order the user chose.
      GRID_CLASSES = "bali-widget-grid grid grid-cols-1 gap-4 md:grid-cols-2 " \
                     "lg:grid-cols-4 lg:auto-rows-[16rem]"

      ADD_TILE_CLASSES = "hidden [.editing_&]:flex flex-col items-center justify-center gap-2 " \
                         "rounded-box border-2 border-dashed border-base-300 " \
                         "text-base-content/50 transition-colors hover:border-primary " \
                         "hover:text-primary"

      def initialize(url:, add_path: nil, **options)
        @url = url
        @add_path = add_path
        @options = build_options(options)
      end

      private

      attr_reader :url, :add_path, :options

      def build_options(opts)
        opts = prepend_controller(opts, "bali-widget-grid edit-mode")
        opts = prepend_values(opts, "bali-widget-grid", widget_grid_values)
        opts = prepend_values(opts, "edit-mode", edit_mode_values)
        opts = prepend_data_attribute(opts, "edit-mode-editing-class", "editing")
        prepend_action(opts, "keydown@window->edit-mode#keydown")
      end

      def widget_grid_values
        {
          url: url,
          moved_text: t("bali_view.widgets.edit.moved"),
          removed_text: t("bali_view.widgets.edit.removed"),
          resized_text: t("bali_view.widgets.edit.resized"),
          failed_text: t("bali_view.widgets.edit.failed")
        }
      end

      def edit_mode_values
        {
          on_text: t("bali_view.widgets.edit.editing_on"),
          off_text: t("bali_view.widgets.edit.editing_off")
        }
      end

      # Dragging is gated on the HANDLE, which is `display:none` outside edit
      # mode, so a card cannot be picked up while you are reading the dashboard.
      # That is the mechanism because `SortableListController` reads `disabled`
      # only at connect — flipping the value would not re-apply.
      #
      # No `data-sortable-update-url` on the cards, so SortableList's own
      # per-item PATCH never fires: it posts a 1-based position for one item
      # where every gesture here writes the whole 0-based sequence.
      def sortable_options
        {
          handle: ".handle",
          class: GRID_CLASSES,
          data: {
            bali_widget_grid_target: "grid",
            action: "bali:sortable-list:end->bali-widget-grid#reordered"
          }
        }
      end
    end
  end
end
```

- [ ] **Step 4: Write the template**

Create `app/components/bali/widget_grid/component.html.erb`:

```erb
<%# Two controllers, composed. `edit-mode` knows nothing about widgets — it
    toggles a mode and remembers it in the URL. `bali-widget-grid` knows nothing
    about the mode — it moves cards and writes the sequence. %>
<%= tag.div(**options) do %>
  <div class="mb-4 flex items-center justify-between gap-2">
    <% if toolbar? %>
      <%= toolbar %>
    <% else %>
      <p class="text-sm text-base-content/60"><%= t('bali_view.widgets.edit.hint') %></p>

      <%# Enter and leave occupy the same slot: the control you press to leave
          should be where the one you pressed to enter was. %>
      <span data-edit-mode-target="enter">
        <%= render Bali::Button::Component.new(
              name: t('bali_view.widgets.edit.edit'), icon: 'pencil',
              variant: :ghost, size: :sm,
              data: { action: 'edit-mode#enter' }) %>
      </span>
      <span data-edit-mode-target="leave" hidden>
        <%= render Bali::Button::Component.new(
              name: t('bali_view.widgets.edit.done'),
              variant: :primary, size: :sm,
              data: { action: 'edit-mode#leave' }) %>
      </span>
    <% end %>
  </div>

  <%# ONE live region for both controllers. A sighted user sees the card move; a
      screen-reader user gets this or silence. %>
  <p role="status" aria-live="polite" class="sr-only"
     data-bali-widget-grid-target="announcer"
     data-edit-mode-target="announcer"></p>

  <% if widgets.any? %>
    <%= render Bali::SortableList::Component.new(**sortable_options) do %>
      <% widgets.each do |widget| %>
        <%= widget %>
      <% end %>

      <%# The "+" tile sits where the widget will land, which teaches the grid in
          a way a header button cannot. It carries no `.handle`, which is the only
          reason it cannot be dragged — the same rule as every card. %>
      <% if add_path.present? %>
        <a href="<%= add_path %>" data-size="small" class="<%= ADD_TILE_CLASSES %>">
          <%= render Bali::Icon::Component.new('plus', size: :medium) %>
          <span class="text-sm font-medium"><%= t('bali_view.widgets.edit.add') %></span>
        </a>
      <% end %>
    <% end %>
  <% elsif empty_state? %>
    <%= empty_state %>
  <% else %>
    <%= render Bali::EmptyState::Component.new(
          title: t('bali_view.widgets.empty.title'),
          description: t('bali_view.widgets.empty.description'),
          icon: 'sparkles') %>
  <% end %>
<% end %>
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rails test test/bali/components/widget_grid_test.rb`
Expected: PASS, 0 failures

- [ ] **Step 6: Run the whole component suite for regressions**

Run: `bundle exec rails test test/bali/components`
Expected: PASS, 0 failures

- [ ] **Step 7: Commit**

```bash
git add app/components/bali/widget_grid/component.rb app/components/bali/widget_grid/component.html.erb test/bali/components/widget_grid_test.rb
git commit -m "feat(widget-grid): add the bento grid component"
```

---

### Task 9: Grid Lookbook preview

**Files:**
- Create: `app/components/bali/widget_grid/preview.rb`
- Create: `app/components/bali/widget_grid/previews/default.html.erb`
- Create: `spec/dummy/app/controllers/widget_layouts_controller.rb`
- Modify: `spec/dummy/config/routes.rb`

The preview needs a live endpoint or every gesture announces "couldn't save" and
the Cypress spec in Task 12 has nothing to assert against. The dummy app gets the
same ~15-line controller a real host writes, which doubles as the worked example
for the docs in Task 13.

- [ ] **Step 1: Write the preview**

Create `app/components/bali/widget_grid/preview.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module WidgetGrid
    class Preview < ApplicationViewComponentPreview
      # Widgets with no host behind them, one per size, so the bento shows all
      # four spans at once.
      class Demo < Bali::Widget::Base
        def self.build(key, size, count)
          Class.new(self) do
            sized size
            define_singleton_method(:key) { key }
            define_singleton_method(:title) { key.humanize }
            define_singleton_method(:short_title) { key.humanize }
            define_singleton_method(:empty_message) { "Nothing here" }
            define_method(:call) do
              Bali::Widget::Result.new(
                count: count,
                view_all_path: "/lookbook",
                items: Array.new(count) { |i| Bali::Widget::Row.new(title: "Row #{i + 1}") }
              )
            end
          end.new
        end
      end

      SPECIMENS = [
        ["overdue_counts", :small, 4],
        ["low_stock_items", :medium, 6],
        ["expiring_stock", :large, 9],
        ["cost_spikes", :wide, 3]
      ].freeze

      # A user-arrangeable dashboard. Press **Edit** to reveal each card's handle,
      # remove button and size picker; drag a card, or focus a handle and use the
      # arrow keys.
      #
      # Every gesture PATCHes the whole layout to `url` — Bali ships no controller,
      # so this preview points at the dummy app's:
      #
      # ```ruby
      # def update
      #   layout.arrange(permitted_layout)
      #   head :no_content
      # end
      # ```
      #
      # @param add_tile toggle
      def default(add_tile: true)
        render_with_template(locals: {
                               widgets: Bali::WidgetGrid::Preview::SPECIMENS.map do |key, size, count|
                                 Bali::WidgetGrid::Preview::Demo.build(key, size, count)
                               end,
                               add_path: add_tile ? "/lookbook" : nil
                             })
      end
    end
  end
end
```

- [ ] **Step 2: Write the preview template**

Create `app/components/bali/widget_grid/previews/default.html.erb`:

```erb
<div class="p-6">
  <%= render Bali::WidgetGrid::Component.new(url: '/widget_layout', add_path: add_path) do |grid| %>
    <% widgets.each do |widget| %>
      <% grid.with_widget(widget) %>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Add the dummy app endpoint**

Create `spec/dummy/app/controllers/widget_layouts_controller.rb`:

```ruby
# frozen_string_literal: true

# The ~15 lines a real host writes. Bali ships no controller and no routes: who
# may see which widget is the host's rule, so the host builds the `offering:` and
# `Bali::Widget::Layout` can only ever subset it.
#
# Here the offering is the preview's own specimens and there is no signed-in
# user, so this exists to make the grid's PATCH succeed — which is what the
# Cypress spec asserts against.
class WidgetLayoutsController < ApplicationController
  skip_forgery_protection

  def update
    head :no_content
  end
end
```

- [ ] **Step 4: Route it**

Add to `spec/dummy/config/routes.rb`, inside the top-level `routes.draw` block:

```ruby
  resource :widget_layout, only: :update
```

- [ ] **Step 5: Verify the preview renders and saves**

Run:

```bash
cd spec/dummy && bin/dev
```

Open `http://localhost:3001/lookbook/preview/bali/widget_grid/default`. Confirm:
the four cards show four different spans at `lg`; **Edit** reveals the chrome and
puts `?editing=1` in the URL; the browser Back button leaves edit mode without
leaving the page; dragging a card by its handle produces a `PATCH /widget_layout`
returning 204 in the network panel; resizing changes the card's span immediately.

Expected: all five behaviours, no console errors.

- [ ] **Step 6: Commit**

```bash
git add app/components/bali/widget_grid/preview.rb app/components/bali/widget_grid/previews/default.html.erb spec/dummy/app/controllers/widget_layouts_controller.rb spec/dummy/config/routes.rb
git commit -m "feat(widget-grid): add the grid Lookbook preview and a dummy endpoint"
```

---

### Task 10: The table and the model

**Files:**
- Create: `db/migrate/20260825120000_create_bali_dashboard_widgets.rb`
- Create: `app/models/bali/dashboard_widget.rb`
- Test: `test/bali/models/dashboard_widget_test.rb`

- [ ] **Step 1: Write the migration**

Create `db/migrate/20260825120000_create_bali_dashboard_widgets.rb`:

```ruby
# frozen_string_literal: true

# One person's dashboard arrangement: which widgets, in what order, at what size.
# A host installs this with `bin/rails bali:install:migrations:dashboard_widgets`.
#
# `owner` is polymorphic because the engine cannot know whether a host's user is
# a `User`, a `Member` or an `Employee` — which is also why the table named for
# one of them would be a lie, and why there is no foreign key pointing into the
# host's schema.
#
# These rows NEVER grant visibility. `Bali::Widget::Layout` is handed the set the
# owner is already authorized for and can only subset and reorder it.
class CreateBaliDashboardWidgets < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_dashboard_widgets do |t|
      # index: false — the unique index below leads with [owner_type, owner_id]
      # and serves every lookup, so the references default would be redundant.
      t.references :owner, polymorphic: true, null: false, index: false

      # The host's scope for this dashboard — a tenant id, or "" for a
      # single-tenant app. NOT NULL with a default rather than nullable: Postgres
      # treats NULLs as DISTINCT in a unique index, so a nullable column would
      # let a single-tenant host store the same widget twice.
      t.string :context, null: false, default: ""

      # Which dashboard, for a host with more than one ("today", "finance").
      t.string :dashboard_key, null: false

      t.string :widget_key, null: false
      t.integer :position, null: false

      # Nullable on purpose: "no opinion", so the widget renders at the size it
      # was drawn around. A row predating a resize still renders.
      t.string :size

      t.timestamps
    end

    # Short names: the autogenerated ones for five columns overrun PostgreSQL's
    # 63-character identifier limit.
    add_index :bali_dashboard_widgets,
              %i[owner_type owner_id context dashboard_key widget_key],
              unique: true, name: "index_bali_dashboard_widgets_uniqueness"
    add_index :bali_dashboard_widgets,
              %i[owner_type owner_id context dashboard_key position],
              name: "index_bali_dashboard_widgets_ordering"
  end
end
```

- [ ] **Step 2: Write the failing test**

Create `test/bali/models/dashboard_widget_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliDashboardWidgetTest < ActiveSupport::TestCase
  # No fixtures in this repo; the house pattern is an inline create.
  # See test/bali/models/saved_view_test.rb.
  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def build(**overrides)
    Bali::DashboardWidget.new({
      owner: owner, context: "1", dashboard_key: "today",
      widget_key: "low_stock_items", position: 0
    }.merge(overrides))
  end

  def test_is_valid_with_the_full_scope
    assert_predicate build, :valid?
  end

  def test_requires_a_dashboard_key_a_widget_key_and_a_position
    refute_predicate build(dashboard_key: nil), :valid?
    refute_predicate build(widget_key: nil), :valid?
    refute_predicate build(position: nil), :valid?
  end

  def test_rejects_a_negative_position
    refute_predicate build(position: -1), :valid?
  end

  def test_a_widget_key_is_unique_within_one_dashboard
    build.save!

    refute_predicate build, :valid?
  end

  def test_the_same_widget_key_is_free_in_another_context_or_dashboard
    build.save!

    assert_predicate build(context: "2"), :valid?
    assert_predicate build(dashboard_key: "finance"), :valid?
  end

  def test_ordered_breaks_ties_on_widget_key
    # Two rows CAN share a position: a row for a widget the owner cannot see
    # keeps its position while the visible ones renumber around it. Without the
    # tie-break Postgres returns those in arbitrary order, which makes
    # Layout#stored_keys nondeterministic.
    build(widget_key: "zulu", position: 0).save!
    build(widget_key: "alpha", position: 0).save!

    assert_equal %w[alpha zulu], Bali::DashboardWidget.ordered.pluck(:widget_key)
  end

  def test_context_defaults_to_the_empty_string_for_a_single_tenant_host
    row = Bali::DashboardWidget.create!(owner: owner, dashboard_key: "today",
                                        widget_key: "solo", position: 0)

    assert_equal "", row.reload.context
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bundle exec rails test test/bali/models/dashboard_widget_test.rb`
Expected: FAIL with `NameError: uninitialized constant Bali::DashboardWidget`

- [ ] **Step 4: Write the model**

Create `app/models/bali/dashboard_widget.rb`:

```ruby
# frozen_string_literal: true

module Bali
  # One chosen dashboard widget: for one owner, in one context, on one dashboard.
  #
  # A row and nothing more. Reading and writing an arrangement belongs to
  # `Bali::Widget::Layout`, which owns the scope this table is keyed by.
  #
  # These rows NEVER grant visibility. `Layout#widgets` is handed the set the
  # owner is already authorized for and can only subset and reorder it. No
  # VISIBLE rows means "never chose" — show everything authorized, in catalog
  # order. (Rows for widgets the owner cannot currently see survive but do not
  # count; see `Layout#visible_keys`.)
  class DashboardWidget < ApplicationRecord
    belongs_to :owner, polymorphic: true

    validates :dashboard_key, presence: true
    validates :widget_key, presence: true,
                           uniqueness: { scope: %i[owner_type owner_id context dashboard_key] }

    # These guard the ActiveRecord paths only — `Layout#arrange` reaches the
    # table through `insert_all`, which bypasses validations and gets its
    # positions from an array index. They exist so a stray `create!` fails with
    # an error naming the column rather than a raw NotNullViolation, and because
    # nothing else stops a negative: there is no CHECK constraint on `position`.
    validates :position, presence: true,
                         numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # NOTE: deliberately NOT `acts_as_list`. The gem's contract is dense,
    # contiguous positions within a scope, and this table does not have that: a
    # row for a widget the owner cannot currently see keeps its position while
    # the visible ones renumber around it, so positions can collide and gaps are
    # normal. `insert_at` is the helper anyone would reach for and it does not
    # behave sanely on a scope with duplicates.
    #
    # NOTE: deliberately no `inclusion` validation of `widget_key`. It would make
    # every legacy row unsaveable the day a widget is retired, blocking unrelated
    # saves, and it duplicates a read-side filter that must exist regardless
    # (`Layout#widgets` drops unknown keys).
    #
    # The same goes for `size`, which is a string and NOT a Rails enum: the
    # `Bali::Widget::SIZES` vocabulary lives there, this column only caches a
    # name from it, and `with_size` coerces on read. An integer enum would also
    # make the persisted meaning positional — and `SIZES` is not ordered by area,
    # so inserting a `tall` where it belongs would silently relabel every row.

    # `widget_key` is the tie-break, and it is load-bearing rather than tidy. Two
    # rows CAN hold the same position (see above); without a second term Postgres
    # returns those in arbitrary order, which makes `Layout#stored_keys`
    # nondeterministic and, through it, `choose`'s "survivors keep their stored
    # order" guarantee unstable.
    scope :ordered, -> { order(:position, :widget_key) }
  end
end
```

- [ ] **Step 5: Install and run the migration in the dummy app**

Run:

```bash
bundle exec rails app:bali:install:migrations:dashboard_widgets
bundle exec rails app:db:migrate
```

Expected: `Copied migration …_create_bali_dashboard_widgets.bali.rb from bali`, then the table created.

- [ ] **Step 6: Run test to verify it passes**

Run: `bundle exec rails test test/bali/models/dashboard_widget_test.rb`
Expected: PASS, 0 failures

- [ ] **Step 7: Commit**

```bash
git add db/migrate/20260825120000_create_bali_dashboard_widgets.rb app/models/bali/dashboard_widget.rb test/bali/models/dashboard_widget_test.rb spec/dummy/db
git commit -m "feat(widget): add the bali_dashboard_widgets table and model"
```

---

### Task 11: `Bali::Widget::Layout`

**Files:**
- Create: `app/lib/bali/widget/layout.rb`
- Test: `test/bali/widget/layout_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/bali/widget/layout_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class BaliWidgetLayoutTest < ActiveSupport::TestCase
  def self.widget(key, size)
    Class.new(Bali::Widget::Base) do
      sized size
      define_singleton_method(:key) { key }
      define_singleton_method(:title) { key }
      def call = Bali::Widget::Result.new
    end
  end

  ALPHA = widget("alpha", :small)
  BRAVO = widget("bravo", :medium)
  CHARLIE = widget("charlie", :large)

  # No fixtures in this repo; the house pattern is an inline create.
  # See test/bali/models/saved_view_test.rb.
  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def offering = [ALPHA.new, BRAVO.new, CHARLIE.new]

  def layout(offer: offering)
    Bali::Widget::Layout.new(owner: owner, context: "1",
                             dashboard_key: "today", offering: offer)
  end

  def keys_of(widgets) = widgets.map(&:key)

  def test_offering_is_required
    assert_raises(ArgumentError) do
      Bali::Widget::Layout.new(owner: owner, dashboard_key: "today")
    end
  end

  def test_with_no_rows_it_returns_the_whole_offering_in_catalog_order
    assert_equal %w[alpha bravo charlie], keys_of(layout.widgets)
    refute_predicate layout, :customized?
  end

  def test_arrange_stores_order_and_size
    layout.arrange([{ widget: CHARLIE.new, size: "wide" }, { widget: ALPHA.new }])

    stored = layout.widgets

    assert_equal %w[charlie alpha], keys_of(stored)
    assert_equal :wide, stored.first.size
    # No size submitted means "no opinion": the widget renders at its own.
    assert_equal :small, stored.last.size
    assert_predicate layout, :customized?
  end

  def test_arrange_is_a_full_reconcile_not_an_append
    layout.arrange([{ widget: ALPHA.new }, { widget: BRAVO.new }])
    layout.arrange([{ widget: BRAVO.new }])

    assert_equal %w[bravo], keys_of(layout.widgets)
  end

  def test_a_retired_size_falls_back_to_the_widget_s_own
    layout.arrange([{ widget: ALPHA.new, size: "enormous" }])

    assert_equal :small, layout.widgets.first.size
  end

  def test_a_stored_key_outside_the_offering_renders_nothing_and_is_not_visible
    layout.arrange([{ widget: ALPHA.new }, { widget: CHARLIE.new }])

    narrowed = layout(offer: [ALPHA.new])

    assert_equal %w[alpha], keys_of(narrowed.widgets)
    assert_equal %w[alpha charlie], narrowed.stored_keys
    assert_equal %w[alpha], narrowed.visible_keys
  end

  def test_a_dashboard_of_only_invisible_rows_falls_back_to_the_offering
    layout.arrange([{ widget: CHARLIE.new }])

    narrowed = layout(offer: [ALPHA.new, BRAVO.new])

    # No VISIBLE rows means "never chose", so this is defaults, not an empty page
    # — and `customized?` must agree, or the host offers "restore defaults" to
    # someone already looking at them.
    assert_equal %w[alpha bravo], keys_of(narrowed.widgets)
    refute_predicate narrowed, :customized?
  end

  def test_choose_keeps_stored_order_for_survivors_and_appends_the_rest
    layout.arrange([{ widget: CHARLIE.new }, { widget: ALPHA.new }])
    layout.choose([ALPHA.new, BRAVO.new, CHARLIE.new])

    assert_equal %w[charlie alpha bravo], keys_of(layout.widgets)
  end

  def test_choose_does_not_resize
    layout.arrange([{ widget: ALPHA.new, size: "wide" }])
    layout.choose([ALPHA.new, BRAVO.new])

    assert_equal :wide, layout.widgets.first.size
  end

  def test_choose_dedupes_so_a_repeated_key_cannot_collide_on_the_unique_index
    layout.choose([ALPHA.new, ALPHA.new])

    assert_equal %w[alpha], layout.stored_keys
  end

  def test_reset_drops_every_row
    layout.arrange([{ widget: ALPHA.new }])
    layout.reset

    assert_empty layout.stored_keys
    assert_equal %w[alpha bravo charlie], keys_of(layout.widgets)
  end

  def test_an_empty_arrange_is_a_reset
    layout.arrange([{ widget: ALPHA.new }])
    layout.arrange([])

    assert_empty layout.stored_keys
  end

  def test_rows_are_scoped_to_the_context_and_dashboard
    layout.arrange([{ widget: ALPHA.new }])

    other_context = Bali::Widget::Layout.new(owner: owner, context: "2",
                                             dashboard_key: "today", offering: offering)
    other_dashboard = Bali::Widget::Layout.new(owner: owner, context: "1",
                                               dashboard_key: "finance", offering: offering)

    assert_empty other_context.stored_keys
    assert_empty other_dashboard.stored_keys
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/bali/widget/layout_test.rb`
Expected: FAIL with `NameError: uninitialized constant Bali::Widget::Layout`

- [ ] **Step 3: Write the implementation**

Create `app/lib/bali/widget/layout.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Widget
    # One owner's dashboard arrangement in one context: which widgets, in what
    # order, at what size. The only thing that reads or writes
    # `bali_dashboard_widgets`.
    #
    # NOT an ActiveRecord model, deliberately. A `dashboards` table would hold an
    # owner, a context and two timestamps — pure join identity, bought with a
    # migration and an extra read on every request, to buy a name we can have for
    # free. Promote it the day a dashboard has state of its own.
    #
    # NOTE `context` here is the SCOPING STRING — a tenant id, or "" for a
    # single-tenant host. It is unrelated to `Bali::Widget::Base#context`, which
    # is the actor object a host's `visible?` gates against. This class never
    # sees that one.
    class Layout
      # The set the owner is being shown right now — already gated by the host.
      # State rather than an argument to three methods, because every one of them
      # needs it and all mean the same thing by it.
      #
      # REQUIRED, with no default, and that is deliberate. An empty offer is a
      # valid state (an owner authorized for nothing) but a terrible default:
      # `arrange` would lose its delete half, since `[] - submitted` is `[]`;
      # `choose` would become a no-op; and `widgets` would render nothing. Three
      # wrong behaviours from one forgotten argument, none of them raising.
      def initialize(owner:, dashboard_key:, offering:, context: "")
        @owner = owner
        @context = context.to_s
        @dashboard_key = dashboard_key.to_s
        @offering = offering
      end

      # EVERY stored key, including rows for widgets the owner cannot currently
      # see. Surfaces almost always want `visible_keys` instead.
      def stored_keys = rows.ordered.pluck(:widget_key)

      # The stored keys the owner can actually see, in stored order.
      #
      # Asking `stored_keys` means "has this owner ever chosen anything"; asking
      # this means "is there anything on their dashboard". A surface that wants
      # the second and asks the first renders defaults while reporting the owner
      # as customized.
      def visible_keys = stored_keys & offering.map(&:key)

      # VISIBLE keys, not rows. An owner whose only stored row is for a hidden
      # widget has customized nothing they can see, and telling them otherwise
      # offers "restore defaults" to someone already looking at defaults.
      def customized? = visible_keys.any?

      # THE INVARIANT.
      #
      # `offering` is ALWAYS the already-authorized set. This indexes what it
      # holds and can only return members of that set; it cannot conjure a
      # widget. Four failure modes collapse into the same `nil` from one lookup:
      #
      #   - a key for a widget whose role the owner lost -> not in `by_key`
      #   - a key for a widget whose feature flag is off -> not in `by_key`
      #   - a key for a widget deleted from the catalog  -> not in `by_key`
      #   - a key hand-edited into the table             -> not in `by_key`
      #
      # Safe by CONSTRUCTION rather than by filtering: the method never sees a
      # list of permitted keys to check against, it sees the widgets themselves
      # and maps over them. That is the difference between a boundary and a habit.
      def widgets
        by_key = offering.index_by(&:key)
        chosen = rows.ordered.pluck(:widget_key, :size).filter_map do |key, size|
          # `with_size` returns the widget at its own size for a nil or retired
          # one, so a row predating the size column still renders.
          by_key[key]&.with_size(size)
        end

        # "No rows means never chose" is really "no VISIBLE rows means never
        # chose": a dashboard holding only hidden ones would otherwise render
        # empty rather than falling back.
        chosen.presence || offering
      end

      # Membership, not order — what a picker submits.
      #
      # A picker renders in stable catalog order, so writing position from THAT
      # order would reshuffle a dashboard the owner had arranged. Survivors keep
      # their stored order; newly chosen widgets append after them.
      #
      # `survivors | submitted` is set-equal to `submitted`: what was stored
      # decides ORDER, never membership. The union also dedupes, so a payload
      # naming one key twice cannot reach `insert_all` as two rows colliding on
      # one unique index, which Postgres refuses outright.
      #
      # A re-chosen widget appends rather than returning to its old slot: absence
      # of a row means "off", so "removed" and "re-added" are the same gesture
      # twice.
      #
      # Sizes are absent from what it hands `arrange`, which is how a picker says
      # "I have no opinion about how big these are". Ticking a box cannot resize.
      #
      # Takes WIDGETS, not keys — see `arrange`.
      def choose(widgets)
        by_key = widgets.index_by(&:key)

        rows.transaction do
          lock_rows
          survivors = stored_keys & by_key.keys

          arrange((survivors | by_key.keys).map { |key| { widget: by_key.fetch(key) } })
        end
      end

      # Reconcile to exactly `layout` — an ordered list of `{ widget:, size: }`,
      # where POSITION IS THE INDEX and a missing size means "no opinion".
      #
      # WIDGETS, not keys. A key is a string and strings arrive from `params`; a
      # widget comes from looking one up in the already-authorized set. The
      # honest claim is that an unauthorized widget cannot get here BY ACCIDENT —
      # not that it cannot get here.
      #
      # An EMPTY layout is a reset, which is what an emptied grid means: no rows
      # means "never chose", so the next read restores every authorized widget.
      def arrange(layout)
        rows.transaction do
          lock_rows
          rows.delete_all

          next if layout.empty?

          Bali::DashboardWidget.insert_all(layout.map.with_index { |item, index| row_for(item, index) })
        end
      end

      # "Restore defaults" and an emptied grid are the same gesture.
      def reset
        rows.transaction { rows.delete_all }
      end

      private

      attr_reader :owner, :context, :dashboard_key, :offering

      # The ONLY place the scope is spelled. Six method bodies re-spelling
      # `where(owner:, context:, dashboard_key:)` is a parameter list describing
      # an object nobody had made.
      def rows
        Bali::DashboardWidget.where(owner: owner, context: context,
                                    dashboard_key: dashboard_key)
      end

      # Two gestures a few milliseconds apart are two complete answers to "what
      # does this dashboard look like". The client serialises its writes; this is
      # what stops two REQUESTS interleaving.
      def lock_rows
        rows.lock.pluck(:id)
      end

      def row_for(item, index)
        now = Time.current

        {
          owner_type: owner.class.polymorphic_name, owner_id: owner.id,
          context: context, dashboard_key: dashboard_key,
          widget_key: item[:widget].key, position: index,
          size: item[:size].presence&.to_s,
          created_at: now, updated_at: now
        }
      end
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rails test test/bali/widget/layout_test.rb`
Expected: PASS, 0 failures

- [ ] **Step 5: Run the whole Ruby suite**

Run: `bundle exec rails test`
Expected: 0 failures, 0 errors

- [ ] **Step 6: Run Rubocop**

Run: `bundle exec rubocop -a app/lib/bali app/models/bali/dashboard_widget.rb app/components/bali/widget app/components/bali/widget_grid test/bali`
Expected: no offenses after autocorrect

- [ ] **Step 7: Commit**

```bash
git add app/lib/bali/widget/layout.rb test/bali/widget/layout_test.rb
git commit -m "feat(widget): add Bali::Widget::Layout"
```

---

### Task 12: Cypress coverage for the Stimulus controllers

**Files:**
- Create: `cypress/e2e/widget-grid.cy.js`

This replaces enjoykitchen's two jsdom test files. Bali has no JS unit runner —
controllers are exercised through Lookbook preview URLs.

- [ ] **Step 1: Write the spec**

Create `cypress/e2e/widget-grid.cy.js`:

```javascript
const PREVIEW = '/lookbook/preview/bali/widget_grid/default'

describe('widget grid', () => {
  beforeEach(() => {
    cy.intercept('PATCH', '/widget_layout').as('save')
    cy.visit(PREVIEW)
  })

  const enterEditMode = () => cy.get('[data-action="edit-mode#enter"]').click()

  // The whole layout travels on every gesture, so one parser serves every test.
  const submittedKeys = (interception) =>
    [...new URLSearchParams(interception.request.body).entries()]
      .filter(([name]) => name === 'widgets[][key]')
      .map(([, value]) => value)

  it('renders one card per widget with its declared size', () => {
    cy.get('.bali-widget-grid > [data-widget-key]').should('have.length', 4)
    cy.get('[data-widget-key="overdue_counts"]').should('have.attr', 'data-size', 'small')
    cy.get('[data-widget-key="cost_spikes"]').should('have.attr', 'data-size', 'wide')
  })

  it('hides the edit chrome until edit mode is entered', () => {
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] .handle').should('be.visible')
  })

  it('remembers edit mode in the URL and leaves it on Back', () => {
    enterEditMode()
    cy.location('search').should('contain', 'editing')
    cy.go('back')
    cy.location('search').should('not.contain', 'editing')
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
  })

  it('leaves edit mode on Escape', () => {
    enterEditMode()
    cy.get('body').type('{esc}')
    cy.get('[data-widget-key="low_stock_items"] .handle').should('not.be.visible')
  })

  it('moves a card with the arrow keys and saves the new order', () => {
    enterEditMode()
    cy.get('[data-widget-key="overdue_counts"] .handle').focus().type('{rightarrow}')

    cy.wait('@save').then((interception) => {
      expect(submittedKeys(interception)[1]).to.equal('overdue_counts')
    })
    // Focus follows the card, not the index — the DOM move blurs the button.
    cy.focused().closest('[data-widget-key]').should('have.attr', 'data-widget-key', 'overdue_counts')
  })

  it('announces the move for screen readers', () => {
    enterEditMode()
    cy.get('[data-widget-key="overdue_counts"] .handle').focus().type('{rightarrow}')
    cy.get('[role="status"]').should('contain', 'position 2 of 4')
  })

  it('resizes a card immediately and saves the size', () => {
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="wide"]').click()

    cy.get('[data-widget-key="low_stock_items"]').should('have.attr', 'data-size', 'wide')
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="wide"]')
      .should('have.attr', 'aria-pressed', 'true')
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="medium"]')
      .should('have.attr', 'aria-pressed', 'false')

    cy.wait('@save').then((interception) => {
      expect(interception.request.body).to.contain('wide')
    })
  })

  it('removes a card, moves focus to a neighbour, and saves the rest', () => {
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-action="bali-widget-grid#remove"]').click()

    cy.get('[data-widget-key="low_stock_items"]').should('not.exist')
    cy.focused().should('have.class', 'handle')

    cy.wait('@save').then((interception) => {
      expect(submittedKeys(interception)).to.not.include('low_stock_items')
      expect(submittedKeys(interception)).to.have.length(3)
    })
  })

  it('collapses a held arrow key into one write', () => {
    enterEditMode()
    cy.get('[data-widget-key="overdue_counts"] .handle')
      .focus()
      .type('{rightarrow}{rightarrow}{rightarrow}')

    cy.wait('@save')
    // The debounce's trailing edge means the three presses are one PATCH; give
    // any second one time to arrive before asserting it did not.
    cy.wait(500)
    cy.get('@save.all').should('have.length', 1)
  })

  it('announces a failure rather than swallowing it', () => {
    cy.intercept('PATCH', '/widget_layout', { statusCode: 500, body: {} }).as('failedSave')
    enterEditMode()
    cy.get('[data-widget-key="low_stock_items"] [data-widget-size="wide"]').click()

    cy.wait('@failedSave')
    cy.get('[role="status"]').should('contain', "Couldn't save")
  })
})
```

- [ ] **Step 2: Start the server**

Run in a separate shell:

```bash
cd spec/dummy && bin/dev
```

Wait for `http://localhost:3001/lookbook` to answer.

- [ ] **Step 3: Run the spec**

Run: `npx cypress run --browser chrome --spec cypress/e2e/widget-grid.cy.js`
Expected: 11 passing, 0 failing

- [ ] **Step 4: Commit**

```bash
git add cypress/e2e/widget-grid.cy.js
git commit -m "test(widget-grid): cover both Stimulus controllers with Cypress"
```

---

### Task 13: Documentation

**Files:**
- Modify: `docs/guides/engine-models.md`
- Modify: `docs/guides/components.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Document the engine model**

Add a section to `docs/guides/engine-models.md`, following the shape of the
existing "Saved views" and "Acknowledgments" sections, after the last one:

````markdown
---

## Dashboard widgets (`bali_dashboard_widgets`)

A user-arrangeable bento dashboard: which widgets, in what order, at what size.

```bash
bin/rails bali:install:migrations:dashboard_widgets
bin/rails db:migrate
```

### The three pieces

`Bali::Widget::Base` is the contract a widget implements. `Bali::Widget::Layout`
reads and writes the arrangement. `Bali::WidgetGrid::Component` renders it.

```ruby
class LowStockItems < Bali::Widget::Base
  sized :medium

  def visible? = context.has_any_role?(:inventory_manager)

  def call = list_from(low_stock.order(:name), view_all_path: items_path)

  private

  def row(item)
    Bali::Widget::Row.new(title: item.name,
                          subtitle: subtitle("#{item.stock} left", item.outlet_name),
                          href: item_path(item))
  end
end
```

`visible?` is a HOOK, never a rule Bali owns: roles, tenancy and feature flags are
things only your app can see. Gate first, then hand the survivors to the layout.

```ruby
def layout
  Bali::Widget::Layout.new(
    owner: current_user,
    context: @tenant.id.to_s,        # "" for a single-tenant app
    dashboard_key: "today",
    offering: Bali::Widget.authorized_for(WIDGETS.map { |k| k.new(pundit_user) })
  )
end
```

`offering:` is the seam that keeps authorization out of Bali. `Layout` can only
subset, reorder and resize what it was handed, so a stale or tampered `widget_key`
finds nothing and is inert. There is no permitted-key list to pass and none to
forget.

### Rendering

```erb
<%= render Bali::WidgetGrid::Component.new(
      url: widget_layout_path, add_path: edit_user_widgets_path) do |grid| %>
  <% @widgets.each do |widget| %>
    <% grid.with_widget(widget) %>
  <% end %>
<% end %>
```

A widget that isn't a list fills the card's `body` slot:

```erb
<% grid.with_widget(widget) do |card| %>
  <% card.with_body { render Compliance::TodayPanel::Component.new(widget.payload) } %>
<% end %>
```

### The write path

Bali ships **no controller and no routes**. Every gesture — drop, arrow move,
remove, resize — PATCHes the same full snapshot to `url:`:

```
widgets[][key]=low_stock_items&widgets[][size]=medium&widgets[][key]=…
```

```ruby
class WidgetLayoutsController < ApplicationController
  def update
    layout.arrange(permitted_layout)
    head :no_content
  end

  private

  # THE BOUNDARY. The one place a submitted string becomes a widget — and it can
  # only produce members of the set the gate returned.
  def permitted_layout
    by_key = layout_offering.index_by(&:key)

    params.expect(widgets: [%i[key size]]).filter_map do |item|
      widget = by_key[item[:key].to_s]
      { widget: widget, size: item[:size] } if widget
    end
  end
end
```

Two behaviours are not obvious and matter:

- **An empty sequence is a reset.** Removing the last widget submits nothing; no
  rows means "never chose", so the next read restores every authorized widget.
  Guard `params[:widgets].blank?` before `expect`, which rejects both an omitted
  key and `[]` as missing.
- **The grid reloads after an empty sequence,** because `204` returns no markup
  and would leave an empty grid on screen over a full dashboard in the database.

| Method | Returns |
|---|---|
| `#widgets` | the offering, subset + reordered + resized |
| `#stored_keys` | every stored key, hidden widgets included |
| `#visible_keys` | stored keys ∩ offering keys, in stored order |
| `#customized?` | whether there is anything visible to reset |
| `#choose(widgets)` | membership; survivors keep order, new ones append |
| `#arrange(layout)` | full reconcile from `[{widget:, size:}, …]` |
| `#reset` | drop every row |

Rows never grant visibility, and a row for a widget the owner can no longer see
survives rather than being deleted — so a temporarily revoked role does not
silently erase someone's arrangement.
````

- [ ] **Step 2: Add both components to the catalog**

Add to `docs/guides/components.md`, in the data-display table (`Bali::Widget`) and
the layout table (`Bali::WidgetGrid`), matching the existing row format:

```markdown
| `Bali::Widget` | Dashboard widget card, four sizes | `card stat list` |
| `Bali::WidgetGrid` | Arrangeable bento of widget cards | `grid` |
```

- [ ] **Step 3: Add a CHANGELOG entry**

Add under the Unreleased heading in `CHANGELOG.md`:

```markdown
### Added

- `Bali::Widget::Component` and `Bali::WidgetGrid::Component`: a user-arrangeable
  bento dashboard — four card sizes, drag and arrow-key reorder, resize, remove —
  with `Bali::Widget::Base` as the widget contract and `Bali::Widget::Layout`
  persisting the arrangement to `bali_dashboard_widgets`. Install the table with
  `bin/rails bali:install:migrations:dashboard_widgets`. Hosts route their own
  PATCH endpoint; see `docs/guides/engine-models.md`.
```

- [ ] **Step 4: Verify the full suite one more time**

Run:

```bash
bundle exec rails test
bundle exec rubocop
yarn check:manifest
```

Expected: 0 failures, no offenses, manifest in sync.

- [ ] **Step 5: Commit**

```bash
git add docs/guides/engine-models.md docs/guides/components.md CHANGELOG.md
git commit -m "docs(widget): document the widget contract, grid and dashboard table"
```

---

## Notes for the implementer

**Zeitwerk risk, Task 1.** `Bali::Widget` is defined by `app/lib/bali/widget.rb`
while `app/components/bali/widget/` contributes `Component` to the same namespace.
Both are engine eager-load paths, so this is a supported "namespace spread over
several root directories". If Task 4 fails with `Bali::Widget::Component` not
found, run `bin/rails zeitwerk:check` in `spec/dummy` before changing anything
else — the fix is structural, not a typo.

**`prepend_values` hyphenizes.** `prepend_values(opts, "bali-widget-grid", moved_text: "…")`
emits `data-bali-widget-grid-moved-text-value`, which the controller reads as
`movedTextValue`. Don't hand-write these attributes.

**Two `context`s.** `Layout.new(context:)` is a scoping STRING (a tenant id).
`Base#context` is the actor object a host's `visible?` gates against. Nothing
passes one where the other is expected, but the names collide when you talk about
them.

**Not in scope.** The membership picker UI, any change to `Bali::SortableList`,
and enjoykitchen's `2.9.2 → 3.x` upgrade (needed before it can adopt any of this,
because commit `09476060` renamed `sortable-list:onEnd` to `bali:sortable-list:end`).
