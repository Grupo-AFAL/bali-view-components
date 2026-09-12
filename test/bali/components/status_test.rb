# frozen_string_literal: true

require "test_helper"

class BaliStatusComponentTest < ComponentTestCase
  OPTIONS = [
    { value: "pending", label: "Pendiente", color: :slate },
    { value: "validated", label: "Validada", color: :green }
  ].freeze

  def test_display_only_renders_static_pill_with_selected_label
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS))
    assert_selector("span.status-component .status-pill.status-pill--static", text: "Validada")
  end

  def test_display_only_does_not_render_a_form_or_buttons
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS))
    assert_no_selector("form")
    assert_no_selector("button")
  end

  def test_named_color_is_applied_as_inline_background_style
    render_inline(Bali::Status::Component.new(selected: "green", options: [ { value: "green", label: "G", color: :green } ]))
    assert_selector('.status-pill[style*="background-color: #16a34a"]')
    assert_selector('.status-pill[style*="color: #fff"]')
  end

  def test_hex_color_is_applied_with_contrasting_text
    render_inline(Bali::Status::Component.new(selected: "x", options: [ { value: "x", label: "X", custom_color: "#ff0000" } ]))
    assert_selector('.status-pill[style*="background-color: #ff0000"]')
    assert_selector('.status-pill[style*="color:"]')
  end

  # The fixed palette is Status's own; the semantic names are everybody's. Both
  # resolve through Bali::Color, so `:success` here means what it means on a Tag.
  def test_semantic_color_resolves_to_the_theme_variable
    render_inline(Bali::Status::Component.new(selected: "x", options: [ { value: "x", label: "X", color: :success } ]))
    assert_selector('.status-pill[style*="background-color: var(--color-success)"]')
    assert_selector('.status-pill[style*="color: var(--color-success-content)"]')
  end

  def test_ghost_takes_the_theme_surface_because_there_is_no_color_ghost
    render_inline(Bali::Status::Component.new(selected: "x", options: [ { value: "x", label: "X", color: :ghost } ]))
    assert_selector('.status-pill[style*="background-color: var(--color-base-200)"]')
  end

  def test_unknown_color_name_is_rejected
    error = assert_raises(ArgumentError) do
      render_inline(Bali::Status::Component.new(
        selected: "x", options: [ { value: "x", label: "X", color: :chartreuse } ]
      ))
    end
    assert_includes(error.message, "unknown color :chartreuse")
  end

  def test_nil_selected_renders_placeholder_none_state
    I18n.with_locale(:es) do
      render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS))
      assert_selector(".status-pill.status-pill--none", text: "Sin estado")
    end
  end

  def test_custom_placeholder_overrides_default
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS, placeholder: "Elegir"))
    assert_selector(".status-pill.status-pill--none", text: "Elegir")
  end

  def test_size_class_is_applied
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, size: :md))
    assert_selector(".status-pill.status--md")
  end

  def test_id_passthrough_lands_on_root_element
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, id: "test_case_1_status"))
    assert_selector("span#test_case_1_status.status-component")
  end

  FORM = { url: "/things/1/status", method: :patch, param: "thing[status]" }.freeze

  def test_editable_renders_a_form_posting_to_the_given_url_and_method
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("form[action='/things/1/status']")
    assert_selector("input[name='_method'][value='patch']", visible: false)
  end

  def test_editable_renders_a_toggle_trigger_wired_to_the_status_controller
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("span.status-component[data-controller='status']")
    assert_selector("button[type='button'][data-status-target='trigger'][data-action='status#toggle'][aria-haspopup='listbox']")
  end

  def test_data_controller_passthrough_preserves_both_controllers
    render_inline(Bali::Status::Component.new(
      selected: "pending", options: OPTIONS, form: FORM, data: { controller: "foo" }
    ))
    assert_selector("span.status-component[data-controller~='status']")
    assert_selector("span.status-component[data-controller~='foo']")
  end

  def test_editable_renders_one_submit_button_per_option_with_name_and_value
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("div.status-panel[role='listbox'] button[type='submit'][role='option']", count: 2, visible: false)
    assert_selector("button.status-option[name='thing[status]'][value='pending']", text: "Pendiente", visible: false)
    assert_selector("button.status-option[name='thing[status]'][value='validated']", text: "Validada", visible: false)
  end

  def test_editable_marks_the_current_option_as_selected
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, form: FORM))
    assert_selector("button.status-option[value='validated'][aria-selected='true']", visible: false)
    assert_selector("button.status-option[value='pending'][aria-selected='false']", visible: false)
  end

  def test_option_rows_carry_their_own_inline_color
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector('button.status-option[value="validated"][style*="background-color: #16a34a"]', visible: false)
  end

  def test_readonly_with_form_renders_static_pill_and_no_form
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM, readonly: true))
    assert_selector(".status-pill.status-pill--static")
    assert_no_selector("form")
    assert_no_selector("[data-controller='status']")
  end

  def test_clearable_renders_a_clear_submit_and_a_none_row_when_a_value_is_selected
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM, clearable: true))
    assert_selector("button.status-pill__clear[type='submit'][name='thing[status]'][value='']")
    assert_selector("button.status-option--none[type='submit'][value='']", visible: false)
  end

  def test_clearable_hides_the_clear_x_when_nothing_is_selected
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS, form: FORM, clearable: true))
    assert_no_selector("button.status-pill__clear")
  end

  # An arbitrary string used to reach the style attribute as-is and rely on
  # `tag.*` escaping to stay inside it. Neither keyword takes an arbitrary string
  # any more: a name has to be in the list, a `custom_color:` has to be a hex.
  def test_a_color_that_is_not_a_name_or_a_hex_never_reaches_the_style_attribute
    %i[color custom_color].each do |param|
      assert_raises(ArgumentError) do
        render_inline(Bali::Status::Component.new(
          selected: "x",
          options: [ { value: "x", label: "X", param => 'red" onmouseover="alert(1)' } ],
          form: { url: "/t", method: :patch, param: "t[s]" }
        ))
      end
    end
  end

  def test_selected_value_absent_from_options_falls_back_to_raw_label_and_default_color
    render_inline(Bali::Status::Component.new(selected: "ghost", options: OPTIONS))
    assert_selector('.status-pill.status-pill--static[style*="background-color: #64748b"]', text: "ghost")
  end

  # `PALETTE` is public API as of v3.1 (#711): hosts paint non-pill things (a
  # Gantt bar) with the pill's colour through this accessor.
  def test_palette_returns_the_bg_fg_pair_for_a_name
    assert_equal({ bg: "#16a34a", fg: "#fff" }, Bali::Status.palette(:green))
    assert_equal({ bg: "#64748b", fg: "#fff" }, Bali::Status.palette("slate"))
  end

  def test_palette_rejects_an_unknown_name_and_lists_the_valid_ones
    error = assert_raises(ArgumentError) { Bali::Status.palette(:magenta) }
    assert_includes error.message, ":magenta"
    assert_includes error.message, ":slate"
  end

  def test_for_builds_the_options_from_the_map_and_selects_the_value
    render_inline(Bali::Status.for("in_progress", map: { pending: :slate, in_progress: :blue }))
    assert_selector('.status-pill.status-pill--static[style*="background-color: #2563eb"]',
                    text: "In progress")
  end

  def test_for_resolves_labels_through_the_i18n_scope
    I18n.backend.store_translations(:en, tasks: { statuses: { done: "Finished" } })
    render_inline(Bali::Status.for(:done, map: { done: :green }, i18n_scope: "tasks.statuses"))
    assert_selector(".status-pill", text: "Finished")
  ensure
    I18n.backend.reload!
  end

  def test_for_passes_component_options_through_including_form
    render_inline(Bali::Status.for("pending",
                                   map: { pending: :slate, done: { color: :green, label: "Done!" } },
                                   form: { url: "/t", method: :patch, param: "t[s]" },
                                   size: :md, id: "task_1_status"))
    assert_selector('span.status-component[id="task_1_status"]')
    assert_selector('button.status-option[value="done"]', text: "Done!", visible: false)
    assert_selector("button.status-option", count: 2, visible: false)
  end

  def test_for_raises_on_an_unmapped_selected_value_without_a_default
    error = assert_raises(ArgumentError) do
      Bali::Status.for("archived", map: { pending: :slate })
    end
    assert_includes error.message, '"archived"'
    assert_includes error.message, "default"
  end

  def test_for_appends_the_default_entry_for_an_unmapped_selected_value
    render_inline(Bali::Status.for("archived", map: { pending: :slate }, default: :gray))
    assert_selector('.status-pill[style*="background-color: #d1d5db"]', text: "Archived")
  end

  def test_for_with_a_nil_value_renders_the_placeholder
    render_inline(Bali::Status.for(nil, map: { pending: :slate }))
    assert_selector(".status-pill.status-pill--none")
  end
end
