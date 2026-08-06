# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderDynamicFieldsConstantsTest < FormBuilderTestCase
  # Bali::FormBuilder::DynamicFields constants

  def test_defines_header_class
    assert_equal("flex justify-between items-center", Bali::FormBuilder::DynamicFields::HEADER_CLASS)
  end

  def test_defines_label_wrapper_class
    assert_equal("flex items-center", Bali::FormBuilder::DynamicFields::LABEL_WRAPPER_CLASS)
  end

  def test_defines_label_class
    assert_equal("label", Bali::FormBuilder::DynamicFields::LABEL_CLASS)
  end

  def test_defines_button_wrapper_class
    assert_equal("flex items-center", Bali::FormBuilder::DynamicFields::BUTTON_WRAPPER_CLASS)
  end

  def test_defines_default_button_class
    assert_equal("btn btn-primary", Bali::FormBuilder::DynamicFields::DEFAULT_BUTTON_CLASS)
  end

  def test_defines_destroy_flag_class
    assert_equal("destroy-flag", Bali::FormBuilder::DynamicFields::DESTROY_FLAG_CLASS)
  end

  def test_defines_default_table_class
    assert_equal("table", Bali::FormBuilder::DynamicFields::DEFAULT_TABLE_CLASS)
  end

  def test_defines_controller_name
    assert_equal("dynamic-fields", Bali::FormBuilder::DynamicFields::CONTROLLER_NAME)
  end

  def test_defines_child_index_placeholder
    assert_equal("new_record", Bali::FormBuilder::DynamicFields::CHILD_INDEX_PLACEHOLDER)
  end

  def test_freezes_all_css_class_constants
    assert(Bali::FormBuilder::DynamicFields::HEADER_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::LABEL_WRAPPER_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::LABEL_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::BUTTON_WRAPPER_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::DEFAULT_BUTTON_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::DESTROY_FLAG_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::CONTROLLER_NAME.frozen?)
    assert(Bali::FormBuilder::DynamicFields::CHILD_INDEX_PLACEHOLDER.frozen?)
    assert(Bali::FormBuilder::DynamicFields::DEFAULT_TABLE_CLASS.frozen?)
  end
end

class BaliFormBuilderLinkToRemoveFieldsTest < FormBuilderTestCase
  # #link_to_remove_fields

  def test_renders_a_button_element
    result = builder.link_to_remove_fields("Remove")
    assert_includes(result, ">Remove<")
    assert_html(result, "button")
  end

  # `<a href="#">` for something that does not navigate is the anti-pattern the
  # repo's own guide forbids: a screen reader announced a link that goes
  # nowhere, and the `#` jumped the page to the top.
  def test_is_not_an_anchor
    result = builder.link_to_remove_fields("Remove")
    refute_html(result, "a")
    refute_includes(result, 'href="#"')
  end

  # These sit inside a `<form>`, where a button with no `type` submits it.
  def test_declares_type_button_so_it_does_not_submit_the_form
    assert_html(builder.link_to_remove_fields("Remove"), 'button[type="button"]')
  end

  def test_adds_stimulus_action_for_removing_fields
    assert_includes(builder.link_to_remove_fields("Remove"), "dynamic-fields#removeFields")
  end

  def test_renders_a_hidden_field_for_destroy
    assert_includes(builder.link_to_remove_fields("Remove"), "_destroy")
  end

  def test_applies_destroy_flag_class_to_hidden_field
    assert_includes(builder.link_to_remove_fields("Remove"), "destroy-flag")
  end
  # with custom class

  def test_with_custom_class_applies_custom_class_to_link
    result = builder.link_to_remove_fields("Remove", class: "btn btn-error")
    assert_includes(result, "btn-error")
  end
  # with data attributes

  def test_with_data_attributes_passes_through_data_attributes
    result = builder.link_to_remove_fields("Remove", data: { testid: "remove-btn" })
    assert_includes(result, 'data-testid="remove-btn"')
  end

  def test_with_data_attributes_merges_action_with_existing_data
    result = builder.link_to_remove_fields("Remove", data: { testid: "remove-btn" })
    assert_includes(result, "dynamic-fields#removeFields")
  end
  # with soft_delete: true

  def test_with_soft_delete_true_renders_hidden_field_for_soft_delete_instead_of_destroy
    soft_delete_resource = Movie.new
    soft_delete_resource.define_singleton_method(:_soft_delete) { nil }
    soft_delete_builder = movie_form_builder(soft_delete_resource)
    result = soft_delete_builder.link_to_remove_fields("Remove", soft_delete: true)
    assert_includes(result, "_soft_delete")
  end

  def test_with_soft_delete_true_does_not_render_destroy_hidden_field
    soft_delete_resource = Movie.new
    soft_delete_resource.define_singleton_method(:_soft_delete) { nil }
    soft_delete_builder = movie_form_builder(soft_delete_resource)
    result = soft_delete_builder.link_to_remove_fields("Remove", soft_delete: true)
    refute_includes(result, "_destroy")
  end
  # with soft_delete: false

  def test_with_soft_delete_false_renders_hidden_field_for_destroy
    result = builder.link_to_remove_fields("Remove", soft_delete: false)
    assert_includes(result, "_destroy")
  end
end

class BaliFormBuilderLinkToRemoveFieldsDestroyFlagTest < FormBuilderTestCase
  # #link_to_remove_fields with destroy_flag: false — array mode has nothing for
  # the server to destroy, so the row carries no flag.

  def test_omits_the_hidden_destroy_field
    result = builder.link_to_remove_fields("Remove", destroy_flag: false)
    refute_includes(result, "_destroy")
    refute_includes(result, "destroy-flag")
  end

  def test_still_renders_the_button_with_its_stimulus_action
    result = builder.link_to_remove_fields("Remove", destroy_flag: false)
    assert_html(result, 'button[type="button"]', text: "Remove")
    assert_includes(result, "dynamic-fields#removeFields")
  end

  def test_does_not_leak_the_option_as_an_html_attribute
    refute_includes(builder.link_to_remove_fields("Remove", destroy_flag: false), "destroy_flag")
  end

  def test_destroy_flag_true_keeps_the_hidden_field
    assert_includes(builder.link_to_remove_fields("Remove", destroy_flag: true), "_destroy")
  end
end

# `dynamic_fields_group` renders a partial, so its view context needs the prefix
# the row partials live under. A bare `ActionController::Base` view context looks
# under `action_controller/base` and finds nothing.
class DynamicFieldsGroupTestCase < FormBuilderTestCase
  private

  # `builder:` is what `form_with builder: Bali::FormBuilder` puts in the
  # options; without it `fields_for` hands the row partial a plain Rails builder
  # that has none of Bali's helpers.
  def group_builder(resource = Movie.new)
    view_context = ActionController::Base.new.view_context
    view_context.lookup_context.prefixes = [ "view_components" ]
    Bali::FormBuilder.new("movie", resource, view_context, builder: Bali::FormBuilder)
  end

  def movie_with_characters(*names)
    Movie.new.tap do |movie|
      names.each { |name| movie.characters.build(name: name) }
    end
  end

  def dom(html)
    Capybara.string(html)
  end

  # Nokogiri parses HTML4, where `<template>` is an unknown element and a `<tr>`
  # inside one outside a table is dropped. The browser keeps it — the HTML5
  # parser switches to "in table body" for exactly this case — so the contents
  # of a template are asserted on the string the server sent, and the parsed-DOM
  # half of the contract lives in cypress/e2e/dynamic-fields-controller.cy.js.
  def template_source(html)
    html[/<template[^>]*>(.*)<\/template>/m, 1].to_s
  end
end

class BaliFormBuilderDynamicFieldsGroupTest < DynamicFieldsGroupTestCase
  # #dynamic_fields_group — default (association) mode

  def test_renders_one_row_per_associated_record
    result = group_builder(movie_with_characters("Alpha", "Beta")).dynamic_fields_group(:characters)
    assert_html(result, ".character-fields", count: 2)
  end

  def test_wraps_the_rows_in_a_div_container
    result = group_builder(movie_with_characters("Alpha")).dynamic_fields_group(:characters)
    assert_html(result, "div[data-dynamic-fields-target='container']")
  end

  def test_declares_the_controller_with_the_row_count_and_selector
    result = group_builder(movie_with_characters("Alpha", "Beta")).dynamic_fields_group(:characters)
    assert_html(result, "div[data-controller='dynamic-fields']")
    assert_html(result, "div[data-dynamic-fields-size-value='2']")
    assert_html(result, "div[data-dynamic-fields-fields-selector-value='.character-fields']")
  end

  def test_names_the_rows_through_nested_attributes
    result = group_builder(movie_with_characters("Alpha")).dynamic_fields_group(:characters)
    assert_includes(result, "movie[characters_attributes][0][name]")
  end

  def test_renders_a_template_with_the_child_index_placeholder
    result = group_builder(movie_with_characters("Alpha")).dynamic_fields_group(:characters)
    assert_includes(result, "movie[characters_attributes][new_record][name]")
  end

  def test_honours_an_explicit_partial_for_both_rows_and_template
    result = group_builder(movie_with_characters("Alpha"))
             .dynamic_fields_group(:characters, partial: "character_row_fields")

    assert_html(result, "tr.character-fields", count: 1)
    assert_includes(result, "movie[characters_attributes][new_record][name]")
  end
end

class BaliFormBuilderDynamicFieldsTableModeTest < DynamicFieldsGroupTestCase
  # #dynamic_fields_group with table: true

  def setup
    @result = group_builder(movie_with_characters("Alpha", "Beta")).dynamic_fields_group(
      :characters, table: true, partial: "character_row_fields",
      columns: [ "#", "Character", "" ]
    )
  end

  def test_renders_the_container_as_a_tbody
    assert_html(@result, "table tbody[data-dynamic-fields-target='container']")
    refute_html(@result, "div[data-dynamic-fields-target='container']")
  end

  def test_puts_the_rows_inside_the_tbody
    assert_html(@result, "tbody[data-dynamic-fields-target='container'] tr.character-fields", count: 2)
  end

  # A `<div>` between `<table>` and `<tbody>` gets hoisted out of the table by
  # the HTML parser, which would strand the add button and its template. Both
  # have to render outside the table to begin with.
  def test_keeps_the_header_and_its_template_outside_the_table
    refute_html(@result, "table template", visible: :all)
    refute_html(@result, "table button[data-dynamic-fields-target='button']")
    assert_html(@result, "template[data-dynamic-fields-target='template']", visible: :all)
  end

  def test_the_template_holds_a_table_row
    assert_includes(template_source(@result), "<tr class=\"character-fields\"")
  end

  def test_renders_the_column_headers
    assert_html(@result, "table thead tr th", count: 3)
    assert_html(@result, "table thead th", text: "Character")
  end

  def test_defaults_the_table_class
    assert_html(@result, "table.table")
  end

  def test_honours_a_custom_table_class
    result = group_builder(movie_with_characters("Alpha")).dynamic_fields_group(
      :characters, table: true, partial: "character_row_fields", table_class: "table table-sm"
    )
    assert_html(result, "table.table.table-sm")
  end

  def test_omits_the_head_when_no_columns_are_given
    result = group_builder(movie_with_characters("Alpha")).dynamic_fields_group(
      :characters, table: true, partial: "character_row_fields"
    )
    refute_html(result, "thead")
  end
end

class BaliFormBuilderDynamicFieldsArrayModeTest < DynamicFieldsGroupTestCase
  # #dynamic_fields_group with array: true

  VALUES = [ { "role" => "Author", "days" => "2" }, { "role" => "Reviewer", "days" => "3" } ].freeze

  def setup
    @result = group_builder.dynamic_fields_group(
      :steps, array: true, partial: "step_fields", values: VALUES
    )
  end

  def test_names_the_inputs_with_the_empty_brackets_rails_reads_as_an_array
    assert_includes(@result, 'name="movie[steps][][role]"')
    assert_includes(@result, 'name="movie[steps][][days]"')
  end

  # `fields_for` would number the rows and suffix the attribute with
  # `_attributes`; array mode does neither.
  def test_does_not_go_through_fields_for
    refute_includes(@result, "steps_attributes")
    refute_includes(@result, "movie[steps][0]")
  end

  def test_renders_one_row_per_value
    assert_html(@result, ".step-fields", count: 2)
  end

  def test_renders_the_values_it_was_given
    assert_html(@result, "input[value='Author']")
    assert_html(@result, "input[value='Reviewer']")
  end

  def test_counts_the_values_in_the_size_value
    assert_html(@result, "div[data-dynamic-fields-size-value='2']")
  end

  def test_derives_the_fields_selector_from_the_singular_attribute_name
    assert_html(@result, "div[data-dynamic-fields-fields-selector-value='.step-fields']")
  end

  def test_renders_a_template_for_the_added_row
    assert_html(@result, "template[data-dynamic-fields-target='template']", visible: :all)
    assert_includes(template_source(@result), 'name="movie[steps][][role]"')
  end

  # Nothing to destroy server-side: the row leaves the DOM on remove.
  def test_carries_no_destroy_flag
    refute_includes(@result, "destroy-flag")
    refute_includes(@result, "_destroy")
  end

  def test_falls_back_to_an_empty_list_when_the_object_has_no_such_attribute
    result = group_builder.dynamic_fields_group(:steps, array: true, partial: "step_fields")

    assert_html(result, ".step-fields", count: 0)
    assert_html(result, "div[data-dynamic-fields-size-value='0']")
  end

  def test_reads_the_rows_off_the_object_when_it_answers_to_the_attribute
    movie = Movie.new
    movie.define_singleton_method(:steps) { [ { "role" => "Owner", "days" => "1" } ] }
    result = group_builder(movie).dynamic_fields_group(:steps, array: true, partial: "step_fields")

    assert_html(result, ".step-fields", count: 1)
    assert_html(result, "input[value='Owner']")
  end
end

class BaliFormBuilderLinkToAddFieldsTest < DynamicFieldsGroupTestCase
  # #link_to_add_fields

  def test_renders_a_button_and_a_template
    result = group_builder.link_to_add_fields("Add", :characters)

    assert_html(result, "button[type='button'][data-dynamic-fields-target='button']", text: "Add")
    assert_html(result, "template[data-dynamic-fields-target='template']", visible: :all)
  end

  def test_template_uses_the_child_index_placeholder
    result = group_builder.link_to_add_fields("Add", :characters)
    assert_includes(result, "movie[characters_attributes][new_record][name]")
  end

  def test_honours_an_explicit_partial
    result = group_builder.link_to_add_fields("Add", :characters, partial: "character_row_fields")
    assert_includes(result, "<tr")
  end

  # Array mode has no association to reflect on, which is what used to make this
  # explode for a JSON attribute.
  def test_array_mode_skips_the_association_reflection
    result = group_builder.link_to_add_fields("Add", :steps, array: true, partial: "step_fields")
    assert_includes(result, 'name="movie[steps][][role]"')
  end

  def test_does_not_leak_its_own_options_as_html_attributes
    result = group_builder.link_to_add_fields("Add", :steps, array: true, partial: "step_fields")
    button = dom(result).find("button[data-dynamic-fields-target='button']")

    refute(button.native.attributes.key?("array"))
    refute(button.native.attributes.key?("partial"))
  end
end
