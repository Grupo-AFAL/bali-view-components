# frozen_string_literal: true

require "test_helper"

class NavigationDeclarationTest < ActiveSupport::TestCase
  setup do
    I18n.backend.store_translations(:en, bali_navigation_declaration_test: {
      modules: { finance: "Finance" },
      sections: { reports: "Reports" },
      items: { invoices: "Invoices", archive: "Archive", settings: "Settings" }
    })
  end

  def navigation(&declaration)
    Class.new(Bali::Navigation::Base) do
      i18n_scope "bali_navigation_declaration_test"
      class_eval(&declaration)
    end
  end

  test "modules hold sections, items written directly in a module form a section of their own" do
    nav = navigation do
      app_module :finance do
        item :invoices, path: "/invoices"
        group :settings do
          item :archive, path: "/archive"
        end
        section :reports do
          item :monthly, path: "/monthly", title: "Monthly"
        end
      end
    end

    finance = nav.find(:finance)
    implicit, reports = finance.children

    assert_equal [ finance ], nav.roots
    assert implicit.implicit?
    assert_equal %i[invoices settings], implicit.children.map(&:key)
    assert_equal [ :archive ], nav.find(:settings).children.map(&:key)
    assert_equal reports, nav.find(:reports)
    assert_equal [ :monthly ], reports.children.map(&:key)
  end

  test "the implicit section is headed by its module's title" do
    nav = navigation do
      app_module :finance do
        item :invoices, path: "/invoices"
      end
    end

    assert_equal "Finance", nav.find(:finance).children.first.title
  end

  test "titles come from the navigation's I18n scope unless one is written" do
    nav = navigation do
      section :reports do
        item :invoices, path: "/invoices"
        item :monthly, path: "/monthly", title: "Monthly"
      end
    end

    assert_equal "Reports", nav.find(:reports).title
    assert_equal "Invoices", nav.find(:invoices).title
    assert_equal "bali_navigation_declaration_test.items.invoices", nav.find(:invoices).title_key
    assert_equal "Monthly", nav.find(:monthly).title
    assert_not nav.find(:monthly).default_title?
  end

  test "the default scope is navigation" do
    nav = Class.new(Bali::Navigation::Base) do
      section(:reports) { item :invoices, path: "/invoices" }
    end

    assert_equal "navigation.sections.reports", nav.find(:reports).title_key
  end

  test "a section without a heading keeps its title" do
    nav = navigation do
      section :reports, heading: false do
        item :invoices, path: "/invoices"
      end
    end

    assert_not nav.find(:reports).heading?
    assert_equal "Reports", nav.find(:reports).title
  end

  test "find returns any node by its key" do
    nav = navigation do
      app_module :finance do
        group(:settings) { item :archive, path: "/archive" }
      end
    end

    assert_kind_of Bali::Navigation::AppModule, nav.find(:finance)
    assert_kind_of Bali::Navigation::Group, nav.find(:settings)
    assert_kind_of Bali::Navigation::Item, nav.find(:archive)
    assert_nil nav.find(:missing)
  end

  test "a key declared twice is refused" do
    error = assert_raises(ArgumentError) do
      navigation do
        section(:reports) { item :invoices, path: "/a" }
        section(:archive) { item :invoices, path: "/b" }
      end
    end

    assert_equal ":invoices is declared twice", error.message
  end

  test "a gate taking the user is refused" do
    error = assert_raises(ArgumentError) do
      navigation { section(:reports) { item :invoices, path: "/a", gate: ->(user) { user.admin? } } }
    end

    assert_match "gates run in the view, use current_user", error.message
  end

  test "a gate that is not a Proc needs authorize first" do
    error = assert_raises(ArgumentError) do
      navigation { section(:reports) { item :invoices, path: "/a", gate: "invoices.index" } }
    end
    assert_match "declare `authorize` before it", error.message

    nav = navigation do
      authorize { |key| key == "invoices.index" }
      section(:reports) { item :invoices, path: "/a", gate: "invoices.index" }
    end
    assert_equal "invoices.index", nav.find(:invoices).gate
  end

  test "the top level holds modules or sections, not both" do
    error = assert_raises(ArgumentError) do
      navigation do
        app_module(:finance) { item :invoices, path: "/a" }
        section(:reports) { item :monthly, path: "/b" }
      end
    end

    assert_match "app modules or sections, not both", error.message
  end

  test "an item or a group outside a section is refused" do
    assert_raises(ArgumentError, match: "outside any section or module") do
      navigation { item :invoices, path: "/a" }
    end
    assert_raises(ArgumentError, match: "outside any section or module") do
      navigation { group(:settings) { item :archive, path: "/a" } }
    end
  end

  test "a module, a section or a group without items is refused" do
    assert_raises(ArgumentError, match: "app_module :finance has no items") { navigation { app_module :finance } }
    assert_raises(ArgumentError, match: "section :reports has no items") { navigation { section :reports } }
    assert_raises(ArgumentError, match: "group :settings has no items") do
      navigation { section(:reports) { group :settings } }
    end
  end

  test "what does not nest is refused" do
    assert_raises(ArgumentError, match: "group :inner cannot go inside group :settings") do
      navigation { section(:reports) { group(:settings) { group(:inner) { item :a, path: "/a" } } } }
    end
    assert_raises(ArgumentError, match: "section :inner cannot go inside section :reports") do
      navigation { section(:reports) { section(:inner) { item :a, path: "/a" } } }
    end
    assert_raises(ArgumentError, match: "app_module :inner cannot go inside app_module :finance") do
      navigation { app_module(:finance) { app_module(:inner) { item :a, path: "/a" } } }
    end
  end

  test "a controllers entry is a namespace" do
    [ "/admin", "admin/", "admin#index", "" ].each do |entry|
      assert_raises(ArgumentError, match: "is not a controller namespace") do
        navigation { section(:reports) { item :invoices, path: "/a", controllers: [ entry ] } }
      end
    end
  end

  # costa-norte and centinela-web have a `Location` model, GC a `Node`: inside a host's
  # `class Navigation < Bali::Navigation::Base` and its lambdas, those names are the host's.
  test "a host constant named like a navigation type is the host's inside the declaration" do
    names = %w[AppModule Claim Group Item Location Menu Node Section]
    names.each { |name| Object.const_set(name, Class.new) }
    host = Module.new
    host.module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
      class Navigation < Bali::Navigation::Base
        section :places, title: "Places" do
          item :place_list, title: "Places", path: "/places",
                            gate: -> { #{names.map { "seen(#{it})" }.join(' && ')} }
        end
      end
    RUBY
    viewer = Struct.new(:seen_constants) do
      def seen(constant) = seen_constants << constant
    end.new([])

    host::Navigation.menu(viewer).sections

    assert_equal names, viewer.seen_constants.map(&:name)
  ensure
    names.each { |name| Object.send(:remove_const, name) if Object.const_defined?(name, false) }
  end

  test "an item needs a path" do
    assert_raises(ArgumentError, match: "item :invoices has no path:") do
      navigation { section(:reports) { item :invoices } }
    end
  end
end
