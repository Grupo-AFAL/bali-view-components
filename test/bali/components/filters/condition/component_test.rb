# frozen_string_literal: true

require "test_helper"

class BaliFiltersConditionComponentTest < ComponentTestCase
  def setup
    @available_attributes = [
      { key: :name, label: "Name", type: :text },
      { key: :status, label: "Status", type: :select,
        options: [ %w[Active active], %w[Inactive inactive] ] },
      { key: :age, label: "Age", type: :number },
      { key: :created_at, label: "Created", type: :date },
      { key: :verified, label: "Verified", type: :boolean }
    ]
    @empty_condition = { attribute: "", operator: "cont", value: "" }
  end

  def test_rendering_renders_the_condition_container
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector(".condition")
    assert_selector('[data-controller="condition"]')
  end

  def test_rendering_renders_attribute_selector_with_all_options
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_select(with_options: %w[Name Status Age Created Verified])
  end

  def test_rendering_renders_operator_selector
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('select[data-condition-target="operator"]')
  end

  def test_rendering_renders_value_input
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('[data-condition-target="valueContainer"]')
  end

  def test_rendering_renders_remove_button
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('button[data-action="condition#remove"]')
  end

  # The note lives OUTSIDE the value container on purpose: the container's innerHTML is
  # rebuilt whenever the operator asks for a different widget, which would take the note
  # with it. It ships hidden — the controller reveals it once the row owes an explanation.
  def test_rendering_renders_the_incomplete_note_hidden_and_outside_the_value_container
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('[data-condition-target="hint"].filters-condition-hint',
      text: "No value chosen, so this condition is ignored", visible: :all)
    assert_no_selector('[data-condition-target="hint"].is-shown', visible: :all)
    assert_no_selector('[data-condition-target="valueContainer"] [data-condition-target="hint"]', visible: :all)
  end

  def test_with_pre_selected_attribute_selects_the_attribute_in_the_dropdown
    condition = { attribute: "name", operator: "cont", value: "John" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('option[value="name"][selected]')
  end

  def test_with_pre_selected_attribute_shows_text_input_for_text_type
    condition = { attribute: "name", operator: "cont", value: "John" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[type="text"][data-condition-target="value"]')
  end

  def test_with_pre_selected_attribute_shows_number_input_for_number_type
    condition = { attribute: "age", operator: "eq", value: "25" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[type="number"][data-condition-target="value"]')
  end

  def test_with_pre_selected_attribute_shows_select_for_select_type
    condition = { attribute: "status", operator: "eq", value: "active" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('select[data-condition-target="value"]')
    assert_select(with_options: %w[Active Inactive])
  end

  def test_select_type_single_value_uses_searchable_slim_select
    condition = { attribute: "status", operator: "eq", value: "active" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('[data-controller="slim-select"] select[data-slim-select-target="select"][data-condition-target="value"]')
    assert_selector('[data-controller="slim-select"][data-slim-select-search-placeholder-value]')
  end

  def test_select_type_slim_select_says_no_results_in_the_page_language
    condition = { attribute: "status", operator: "eq", value: "active" }
    I18n.with_locale(:es) do
      render_inline(Bali::Filters::Condition::Component.new(
        condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
      ))
    end
    assert_selector('[data-controller="slim-select"][data-slim-select-no-results-text-value="Sin resultados"]')
  end

  # The value widget the controller builds when the user picks a select-type attribute
  # reads its texts from here, not from the markup above.
  def test_translations_carry_the_no_results_text_for_the_select_built_in_js
    I18n.with_locale(:es) do
      render_inline(Bali::Filters::Condition::Component.new(
        condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
      ))
    end
    translations = JSON.parse(page.find('[data-controller="condition"]')["data-condition-translations-value"])
    assert_equal "Sin resultados", translations["no_results"]
  end

  # The row paints no caption for any of its controls. cypress/e2e/filters-condition-names.cy.js
  # reads the same names from the accessibility tree, SlimSelect's combobox included.
  def test_names_the_field_and_the_operator_in_the_page_language
    I18n.with_locale(:es) do
      render_inline(Bali::Filters::Condition::Component.new(
        condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
      ))
    end
    assert_selector('select[data-condition-target="attribute"][aria-label="Campo"]')
    assert_selector('select[data-condition-target="operator"][aria-label="Operador"]')
  end

  VALUE_WIDGETS = {
    { attribute: "name", operator: "cont" } => 'input[type="text"][data-condition-target="value"]:not([data-controller])',
    { attribute: "age", operator: "eq" } => 'input[type="number"][data-condition-target="value"]',
    { attribute: "created_at", operator: "eq" } =>
      'input[data-controller="datepicker"][data-condition-target="value"]:not([data-datepicker-enable-time-value])',
    { attribute: "created_at", operator: "between" } =>
      'input[data-controller="datepicker"][data-condition-target="rangeInput"]:not([data-datepicker-enable-time-value])',
    { attribute: "logged_in_at", operator: "eq" } =>
      'input[data-controller="datepicker"][data-condition-target="value"][data-datepicker-enable-time-value="true"]',
    { attribute: "logged_in_at", operator: "between" } =>
      'input[data-controller="datepicker"][data-condition-target="rangeInput"]:not([data-datepicker-enable-time-value])',
    { attribute: "verified", operator: "eq" } => 'select[data-condition-target="value"]:not([data-slim-select-target])',
    { attribute: "status", operator: "eq" } => 'select[data-slim-select-target="select"]'
  }.freeze

  def test_names_every_value_widget_in_the_page_language
    attributes = @available_attributes + [ { key: :logged_in_at, label: "Logged in", type: :datetime } ]
    VALUE_WIDGETS.each do |condition, widget|
      I18n.with_locale(:es) do
        render_inline(Bali::Filters::Condition::Component.new(
          condition: condition, group_index: 0, condition_index: 0, available_attributes: attributes
        ))
      end
      assert_selector("#{widget}[aria-label=\"Valor\"]")
    end
  end

  def test_a_datetime_range_picks_whole_days
    render_inline(Bali::Filters::Condition::Component.new(
      condition: { attribute: "logged_in_at", operator: "between" }, group_index: 0, condition_index: 0,
      available_attributes: @available_attributes + [ { key: :logged_in_at, label: "Logged in", type: :datetime } ]
    ))

    assert_selector('input[data-condition-target="rangeInput"][data-datepicker-alt-format-value="M j, Y"]' \
                    ":not([data-datepicker-enable-time-value])")
    assert_selector('input[data-condition-target="rangeInput"][placeholder="Select date range..."]')
  end

  # Whatever is chosen, the server paints "Select values..." here: multi_select_controller.js
  # writes the choices in on connect, so the name they give it is read in
  # cypress/e2e/filters-condition-names.cy.js.
  def test_leaves_the_multi_select_trigger_named_by_its_contents
    render_inline(Bali::Filters::Condition::Component.new(
      condition: { attribute: "status", operator: "in" }, group_index: 0, condition_index: 0,
      available_attributes: @available_attributes
    ))
    assert_selector('[data-multi-select-target="trigger"]:not([aria-label]):not([aria-labelledby])')
  end

  # condition_controller.js#buildMultiSelectInput builds this same markup when the operator
  # changes in the browser, and cypress/e2e/filters-built-multi-select.cy.js holds the two
  # equal. A daisyUI .dropdown there opened its panel on focus, with nothing telling the
  # trigger had one (#1282).
  def test_the_multi_select_opens_only_on_its_controllers_toggle
    render_inline(Bali::Filters::Condition::Component.new(
      condition: { attribute: "status", operator: "in" }, group_index: 0, condition_index: 0,
      available_attributes: @available_attributes
    ))

    trigger = '[data-multi-select-target="trigger"]'
    assert_selector %(#{trigger}[role="button"][tabindex="0"][aria-expanded="false"]:not([aria-haspopup]))
    assert_equal %w[click->multi-select#toggle keydown.enter->multi-select#toggle:prevent
                    keydown.space->multi-select#toggle:prevent], page.find(trigger)["data-action"].to_s.split
    assert_selector('[data-multi-select-target="dropdown"].hidden', visible: :all)
    assert_no_selector(".dropdown, .dropdown-content", visible: :all)
  end

  # condition_controller.js rebuilds the value widget whenever the field changes, and names
  # it from here.
  def test_translations_carry_the_name_of_the_value_widget_built_in_js
    I18n.with_locale(:es) do
      render_inline(Bali::Filters::Condition::Component.new(
        condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
      ))
    end
    translations = JSON.parse(page.find('[data-controller="condition"]')["data-condition-translations-value"])
    assert_equal "Valor", translations["value_aria_label"]
  end

  def test_with_pre_selected_attribute_shows_select_for_boolean_type
    condition = { attribute: "verified", operator: "eq", value: "true" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('select[data-condition-target="value"]')
    assert_select(with_options: %w[Any Yes No])
  end

  def test_with_pre_selected_attribute_shows_date_input_for_date_type
    condition = { attribute: "created_at", operator: "eq", value: "2026-01-01" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[data-controller="datepicker"]')
  end

  def test_field_name_builds_correct_ransack_field_name
    condition = { attribute: "status", operator: "eq", value: "active" }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 1, condition_index: 0, available_attributes: @available_attributes
    )
    assert_equal("q[g][1][status_eq]", component.field_name)
  end

  def test_field_name_uses_placeholder_for_empty_attribute
    component = Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    assert_equal("q[g][0][__ATTR___cont]", component.field_name)
  end

  def test_operators_for_current_type_returns_operators_for_the_selected_attribute_type
    condition = { attribute: "age", operator: "eq", value: "" }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    operators = component.operators_for_current_type
    assert_includes(operators.pluck(:value), "eq")
    assert_includes(operators.pluck(:value), "gt")
    assert_includes(operators.pluck(:value), "lt")
  end

  def test_operators_for_current_type_defaults_to_text_operators_when_no_attribute_selected
    component = Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    operators = component.operators_for_current_type
    assert_includes(operators.pluck(:value), "cont")
    assert_includes(operators.pluck(:value), "eq")
  end

  def test_multiple_operator_returns_true_for_in_operator
    condition = { attribute: "status", operator: "in", value: [] }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    assert(component.multiple_operator?)
  end

  def test_multiple_operator_returns_true_for_not_in_operator
    condition = { attribute: "status", operator: "not_in", value: [] }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    assert(component.multiple_operator?)
  end

  def test_multiple_operator_returns_false_for_eq_operator
    condition = { attribute: "status", operator: "eq", value: "active" }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    refute(component.multiple_operator?)
  end

  # condition_controller.js#operatorFlag reads the same mark off the <option>, and
  # cypress/e2e/filters-condition-controller.cy.js holds the browser to it.
  def test_the_widget_follows_the_mark_operators_for_type_puts_on_the_operator
    multiple = marked_condition({ attribute: "status", operator: "eq" }, :multiple)
    range = marked_condition({ attribute: "created_at", operator: "gt" }, :range)

    assert(multiple.multiple_operator?)
    assert(range.range_operator?)
  end

  private

  def marked_condition(condition, mark)
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    marked = component.operators_for_current_type.map do |op|
      op[:value] == condition[:operator] ? op.merge(mark => true) : op
    end
    component.tap { |c| c.define_singleton_method(:operators_for_current_type) { marked } }
  end
end
