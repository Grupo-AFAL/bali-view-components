# frozen_string_literal: true

require "test_helper"

# #1530. ransack 6 makes `cont`, `start` and `end` case-sensitive on PostgreSQL and adds `i_start`
# and `i_end` beside `i_cont`. Bali reads and writes the plain predicates under ransack 5, as it
# always did, and writes their `i_` twins under 6 (`Bali::RansackParamName.case_insensitive_text?`),
# where what a saved view, the filter cache or a bookmark carries from before keeps applying.
#
# The tests that flip the switch (`as_ransack`) never run `i_start` or `i_end`, which ransack 5 lacks.
class BaliFilterFormTextPredicatesTest < ComponentTestCase
  include RansackTestHelpers

  class SearchFilterForm < Bali::FilterForm
    search_fields :name, :genre

    filter_attribute :name, type: :text
    filter_attribute :genre, type: :select, options: [ %w[Drama Drama], %w[Action Action] ]
  end

  # afal-apps' Finance::Terminals::Finding and bali-auth's AuditLog: a search scope named after the
  # `_cont` the box submitted, allowlisted as a Symbol like bali-auth's.
  class ScopedSearchMovie < ActiveRecord::Base
    self.table_name = "movies"

    scope :code_cont, ->(term) { where("name LIKE ?", "%#{sanitize_sql_like(term)}%") }

    def self.ransackable_attributes(_auth_object = nil) = %w[name]
    def self.ransackable_associations(_auth_object = nil) = []
    def self.ransackable_scopes(_auth_object = nil) = %i[code_cont]
  end

  class ScopedSearchFilterForm < Bali::FilterForm
    search_fields :code
  end

  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  PLAIN = %w[cont eq start end not_cont not_eq].freeze
  CASE_INSENSITIVE = %w[i_cont eq i_start i_end not_i_cont not_eq].freeze

  def setup
    studio = Tenant.create!(name: "Acme")
    @seidor = Movie.create!(name: "Seidor Analytics", genre: "Drama", studio: studio)
    @acme = Movie.create!(name: "Acme", genre: "Action", studio: studio)
  end

  test "the switch is whether the installed ransack is 6" do
    assert_equal Gem::Version.new(Ransack::VERSION) >= Gem::Version.new("6.0"),
                 Bali::RansackParamName.case_insensitive_text?
  end

  test "ransack 5 gets the plain text predicates and ransack 6 their i_ twins" do
    { false => PLAIN, true => CASE_INSENSITIVE }.each do |insensitive, operators|
      as_ransack(insensitive) do
        assert_equal operators, Bali::Filters::Operators.for_type(:text).pluck(:value)
        assert_equal "name_or_genre_#{operators.first}", SearchFilterForm.new(Movie.all).search_field_name
        assert_equal "q[name_or_genre_#{operators.first}]", Bali::SearchConfig.new(fields: %i[name genre]).param_name

        # condition_controller.js#reset takes the first text operator from these same translations.
        render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: [ { key: :name, type: :text } ],
                                                   popover: false))
        # The rows a <template> holds (a new group, a new condition) are not in Capybara's tree.
        assert_equal [ operators.first ],
                     rendered_content.scan(/data-condition-target="operatorHidden"\s+value="([^"]*)"/).flatten.uniq
        translations = JSON.parse(page.find('[data-controller="condition"]', match: :first)["data-condition-translations-value"])
        assert_equal operators.first, translations.dig("operators", "text", 0, "value")
      end
    end
  end

  # Condition::Component#operator paints it with the first text operator, under either ransack.
  test "a group the panel cannot draw hands a host a blank row with no operator" do
    undrawable = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(q: { g: { "0" => { "name_null" => "1" } } }))

    assert_equal [ { attribute: "", operator: nil, value: "" } ], undrawable.filter_groups.sole[:conditions]
  end

  test "the search's names come from its fields alone, for a guard that runs before the form" do
    { false => %w[name_or_genre_cont], true => %w[name_or_genre_i_cont name_or_genre_cont] }.each do |insensitive, names|
      as_ransack(insensitive) do
        assert_equal names, Bali::RansackParamName.predicates(%i[name genre]), insensitive
        assert_equal names, SearchFilterForm.new(Movie.all).search_param_names, insensitive
      end
    end
    assert_empty Bali::RansackParamName.predicates([])
  end

  test "under ransack 5 the search is read under its _cont alone, as it always was" do
    as_ransack(false) do
      assert_equal %w[name_or_genre_cont], SearchFilterForm.new(Movie.all).search_param_names

      unread = form(name_or_genre_i_cont: "seidor")
      assert_nil unread.search_value
      assert_empty unread.active_filters
      assert_equal 2, unread.result.count
    end
  end

  test "under ransack 6 a search written with _cont still searches and fills the box" do
    as_ransack(true) do
      assert_equal %w[name_or_genre_i_cont name_or_genre_cont], SearchFilterForm.new(Movie.all).search_param_names

      %w[name_or_genre_i_cont name_or_genre_cont].each do |key|
        searched = form(key => "seidor")

        assert_equal "seidor", searched.search_value, key
        assert_equal({ "name_or_genre_i_cont" => "seidor" }, searched.active_filters, key)
        assert_equal [ @seidor ], searched.result.to_a, key
      end
    end
  end

  test "under ransack 6 a text condition written before is painted as its i_ twin" do
    as_ransack(true) do
      applied = form(g: { "0" => { name_cont: "seidor" }, "1" => { name_not_cont: "seidor" },
                          "2" => { name_start: "Seid" }, "3" => { name_end: "tics" }, "4" => { name_i_cont: "acme" } })

      assert_equal [ [ "name", "i_cont", "seidor" ], [ "name", "not_i_cont", "seidor" ], [ "name", "i_start", "Seid" ],
                     [ "name", "i_end", "tics" ], [ "name", "i_cont", "acme" ] ], conditions(applied)
      assert_equal [ "contains", "does not contain", "starts with", "ends with", "contains" ],
                   conditions(applied).map { |_, operator, _| Bali::Filters::Operators.label_for(operator, :text) }
    end
  end

  test "under ransack 5 an i_ condition is no filter, as it never was" do
    as_ransack(false) do
      applied = form(g: { "0" => { name_i_cont: "seidor", name_cont: "acme" }, "1" => { name_i_start: "Seid" } })

      assert_equal [ [ "name", "cont", "acme" ] ], conditions(applied)
    end
  end

  # Whichever ransack runs the suite, the plain conditions an app on 5 wrote keep filtering.
  test "the installed ransack applies the conditions written before" do
    applied = form(g: { "0" => { name_cont: "SEIDOR", name_start: "seid", name_end: "TICS" } })

    assert_equal [ text("cont"), text("start"), text("end") ], conditions(applied).map(&:second)
    assert_equal [ @seidor ], applied.result.to_a
  end

  test "a view saved before ransack 6 applies under it, and is the view the listing is on" do
    as_ransack(true) do
      payload = { "groupings" => { "0" => { "name_cont" => "seidor" } } }
      opened = open_view(payload)

      assert_equal [ [ "name", "i_cont", "seidor" ] ], conditions(opened)
      assert opened.state_matches_current_state?(payload)
    end
    as_ransack(false) { assert_empty open_view({ "groupings" => { "0" => { "name_i_cont" => "seidor" } } }).filter_groups }
  end

  test "under ransack 6 Apply on a panel opened with cont writes i_cont" do
    as_ransack(true) do
      opened = form(g: { "0" => { name_cont: "seidor" } })
      render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: opened.available_attributes,
                                                 filter_form: opened, popover: false))

      assert_selector "[data-filters-target='groupsContainer'] input[name='q[g][0][name_i_cont]'][value='seidor']"
    end
  end

  test "under ransack 6 a text operator written by hand paints as its i_ twin" do
    { true => %w[i_cont i_cont], false => %w[cont i_cont] }.each do |insensitive, painted|
      as_ransack(insensitive) do
        %w[cont i_cont].zip(painted).each do |written, expected|
          condition = Bali::Filters::Condition::Component.new(
            condition: { attribute: "name", operator: written, value: "a" }, group_index: 0, condition_index: 0,
            available_attributes: [ { key: :name, type: :text } ]
          )

          assert_equal expected, condition.operator, "#{insensitive} #{written}"
        end
        assert_equal "contains", Bali::Filters::Operators.label_for("cont", :text)
      end
    end
  end

  test "a scope named after the box's _cont keeps that name under ransack 6" do
    [ false, true ].each do |insensitive|
      as_ransack(insensitive) do
        box = Bali::RansackParamName.predicate(:code)
        searched = ScopedSearchFilterForm.new(ScopedSearchMovie.all, ActionController::Parameters.new(q: { box => "seid" }))

        assert_equal "code_cont", searched.search_field_name, box
        assert_equal [ box, "code_cont" ].uniq, searched.search_param_names, box
        assert_equal [ @seidor.id ], searched.result.pluck(:id), box
      end
    end
  end

  test "under ransack 6 an attribute's operators may be written in either variant" do
    as_ransack(true) do
      declared = Class.new(Bali::FilterForm) do
        filter_attribute :name, type: :text, operators: %i[cont i_start], default_operator: :start
      end.new(Movie.all).available_attributes.sole
      by_hand = { key: :name, type: :text, operators: %w[i_cont start], default_operator: "i_start" }

      [ declared, by_hand ].each do |attribute|
        assert_equal %w[i_cont i_start], Bali::Filters::Operators.for_attribute(attribute).pluck(:value)
        assert_equal "i_start", Bali::Filters::Operators.default_for(attribute)
      end
    end
    as_ransack(false) do
      error = assert_raises(ArgumentError) { Class.new(Bali::FilterForm) { filter_attribute :name, operators: %i[i_cont] } }
      assert_match(/offers no operator i_cont/, error.message)
    end
  end

  # identity's AccountsFilterForm declares the box's `_cont` as an attribute too (#1017): under
  # ransack 6 the box submits `_i_cont`, and clearing the search has to close that door as well.
  class DoorFilterForm < Bali::FilterForm
    search_fields :name, :genre

    attribute :name_or_genre_cont
  end

  test "clearing the search closes a door declared under the other variant" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    as_ransack(true) do
      DoorFilterForm.new(Movie.all, ActionController::Parameters.new(q: { name_or_genre_cont: "seidor" }), storage_id: "movies")
      cleared = DoorFilterForm.new(Movie.all, ActionController::Parameters.new(clear_search: true),
                                   storage_id: "movies", persist_enabled: true)

      assert_nil cleared.search_value
      assert_nil cleared.name_or_genre_cont
      assert_equal 2, cleared.result.count
    end
  ensure
    Rails.cache = original_cache
  end

  private

  # What `case_insensitive_text?` memoizes from the gem, set for the block.
  def form(q)
    SearchFilterForm.new(Movie.all, ActionController::Parameters.new(q: q))
  end

  def open_view(payload)
    SearchFilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"),
                         saved_views_store: Store.new(View.new(1, "Seidor", payload)))
  end
end
