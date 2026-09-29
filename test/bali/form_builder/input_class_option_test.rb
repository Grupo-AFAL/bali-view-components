# frozen_string_literal: true

require "test_helper"

# `input_class:` classes the control itself — the `<input>`, `<select>`,
# `<textarea>` or `<trix-editor>` — and nothing else. It is the fourth and last
# destination in the builder, and #1147 is the issue that asked for it.
#
# Why the three that already existed are not enough, measured in Chromium
# against the dummy's compiled sheet:
#
#   * `class:` lands on the `<fieldset>` AND the control. `bg-warning/20` that
#     way paints a tinted band across the whole group, caption included.
#   * `control_class:` lands on the box around the control, which sits BEHIND
#     it: the `.control` div takes the tint and the input keeps its own opaque
#     `oklch(1 0 0)` on top of it. `rounded-2xl border-2 border-error` on the
#     box draws a second, larger frame around an input still at 4px and 1px.
#   * `input_class:` puts all three on the input, and on nothing else.
#
# Width is the exception, and it belongs to `control_class:`: every Bali control
# carries `w-full`, so `input_class: "w-32"` loses to it (measured: 1248px, not
# 128px) while `control_class: "max-w-32"` sizes the box the control fills —
# 128px on every family, the date ones included. See "Which class lands where"
# in docs/guides/form-builder.md.
#
# So the contract has two outcomes and every family has to be in one of them by
# name: the class reaches the control, or the family renders no control it could
# reach and the class reaches nothing at all — never an attribute in the DOM,
# never a silent landing somewhere else.
class BaliFormBuilderInputClassOptionTest < FormBuilderTestCase
  PROBE = "probe-input-class"

  # What counts as "the control": the elements the user actually types into or
  # picks from. `<trix-editor>` is one — it is the editor, not a widget over a
  # hidden field — and the BlockNote editor is not, which is why the two live in
  # different camps below.
  CONTROLS = "input, select, textarea, trix-editor"

  CARRIES = {
    "text_group" => ->(b, o) { b.text_group(:name, **o) },
    "email_group" => ->(b, o) { b.email_group(:name, **o) },
    "url_group" => ->(b, o) { b.url_group(:name, **o) },
    "password_group" => ->(b, o) { b.password_group(:name, **o) },
    "number_group" => ->(b, o) { b.number_group(:budget, **o) },
    "month_group" => ->(b, o) { b.month_group(:release_date, **o) },
    "text_area_group" => ->(b, o) { b.text_area_group(:synopsis, **o) },
    "date_group" => ->(b, o) { b.date_group(:release_date, **o) },
    "datetime_group" => ->(b, o) { b.datetime_group(:release_date, **o) },
    "time_group" => ->(b, o) { b.time_group(:duration, **o) },
    "search_group" => ->(b, o) { b.search_group(:name, **o) },
    "currency_group" => ->(b, o) { b.currency_group(:budget, **o) },
    "percentage_group" => ->(b, o) { b.percentage_group(:budget, **o) },
    "numeric_group" => ->(b, o) { b.numeric_group(:budget, **o) },
    "step_number_group" => ->(b, o) { b.step_number_group(:duration, **o) },
    "range_group" => ->(b, o) { b.range_group(:rating, **o) },
    "boolean_group" => ->(b, o) { b.boolean_group(:indie, **o) },
    "switch_group" => ->(b, o) { b.switch_group(:indie, **o) },
    "radio_group" => ->(b, o) { b.radio_group(:status, [ %w[One 1] ], **o) },
    "rich_text_area_group" => ->(b, o) { b.rich_text_area_group(:synopsis, **o) },
    # The families that take a second `html:` hash read it off the group hash,
    # so a top-level `input_class:` reaches the element there too. `html:
    # { class: }` is the older spelling for the same destination and still works
    # — asserted below.
    "select_group" => ->(b, o) { b.select_group(:status, [], **o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:status, [], **o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, **o) }
  }.freeze

  # Families with no control the option could reach, each for a measured reason
  # and each with another way to say the same thing:
  #
  # `file_group`: its `<input type="file">` is forced to `INPUT_CLASS` and
  # hidden — the button the user sees is drawn beside it, and `file_class:` is
  # what classes the thing on screen.
  #
  # `block_editor_group` / `rich_text_group`: what the user types into is a
  # ProseMirror `contenteditable` BlockNote builds client-side, so at render
  # time there is no element to class. (`rich_text_area_group` is the Trix one
  # and IS in the list above — different component, confusable name.)
  #
  # `radio_buttons_group`: the radios it renders take a fixed option hash of the
  # family's own, so no class option of any kind reaches them today — not
  # `class:` either. `control_class:` classes the group container and
  # `radios: { class: ... }` each category's.
  #
  # `coordinates_polygon_group`, `recurrent_event_rule_group`,
  # `direct_upload_group` and `time_period_group` are widgets over a hidden
  # input: the control is the widget's own markup, not one element.
  #
  # `submit_group` is the actions row: no control at all. `button_class:` is
  # what classes the button.
  DROPS = {
    "file_group" => ->(b, o) { b.file_group(:name, **o) },
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "rich_text_group" => ->(b, o) { b.rich_text_group(:synopsis, **o) },
    "radio_buttons_group" => ->(b, o) { b.radio_buttons_group(:status, { a: [ %w[One 1] ] }, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "recurrent_event_rule_group" => ->(b, o) { b.recurrent_event_rule_group(:rule, **o) },
    "direct_upload_group" => ->(b, o) { b.direct_upload_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    "submit_group" => ->(b, o) { b.submit_group("Save", **o) }
  }.freeze

  # Renders a button and a container for nested records, never a control of its
  # own, and needs a real association to render at all. Named here rather than
  # left out silently, so the coverage check below stays a check.
  UNSWEPT_GROUPS = %w[dynamic_fields_group].freeze

  def test_every_group_helper_is_covered_by_this_sweep
    swept = CARRIES.keys + DROPS.keys + UNSWEPT_GROUPS
    uncovered = live_group_helpers - swept

    assert_empty uncovered,
                 "Group helpers with no `input_class:` expectation, so nothing says whether " \
                 "the option does anything there: #{uncovered.sort.inspect}. " \
                 "Add each to CARRIES or DROPS."
  end

  def test_input_class_reaches_the_control
    missing = CARRIES.filter_map do |name, render|
      marked = probed(render.call(builder, { input_class: PROBE, label: "L" }))
      next "#{name}: the class reached no element" if marked.empty?

      wrong = marked.reject { |node| node.matches?(CONTROLS) }
      "#{name}: #{wrong.map { |n| n.name }.inspect}" if wrong.any?
    end

    assert_empty missing,
                 "`input_class:` never reached the control:\n#{missing.join("\n")}"
  end

  # The whole point of a fourth name: it reaches the control WITHOUT reaching
  # the group around it, which is what `class:` cannot help doing.
  def test_input_class_stays_off_the_fieldset_and_off_the_box
    landed = CARRIES.filter_map do |name, render|
      html = render.call(builder, { input_class: PROBE, label: "L" })
      found = probed(html).reject { |node| node.matches?(CONTROLS) }
                          .map { |node| "#{node.name}.#{node['class']}" }
      "#{name}: #{found.inspect}" if found.any?
    end

    assert_empty landed,
                 "`input_class:` landed on something that is not the control:\n" \
                 "#{landed.join("\n")}"
  end

  def test_the_families_with_no_reachable_control_render_it_nowhere
    landed = DROPS.filter_map do |name, render|
      html = render.call(builder, { input_class: PROBE, label: "L" })
      found = probed(html).map { |node| "#{node.name}.#{node['class']}" }
      "#{name}: #{found.inspect}" if found.any?
    end

    assert_empty landed,
                 "A family with no control took `input_class:` anyway, so this sweep no " \
                 "longer describes it:\n#{landed.join("\n")}"
  end

  # The #1111 failure mode: Rails forwards what it does not recognise, so a
  # reserved key that is not a real attribute paints itself onto the element.
  # `block_editor_group` rendered `<div input_class="...">` until its own
  # extraction list learned the key.
  def test_the_option_never_reaches_the_dom_as_an_attribute
    leaks = CARRIES.merge(DROPS).filter_map do |name, render|
      html = render.call(builder, { input_class: PROBE, label: "L" })
      found = attribute_names(html).grep(/\Ainput.class\z/)
      "#{name}: #{found.inspect}" if found.any?
    end

    assert_empty leaks, "`input_class:` rendered as an HTML attribute:\n#{leaks.join("\n")}"
  end

  # `token_list`, not interpolation — the same spellings the `<fieldset>` has
  # always taken.
  def test_it_takes_an_array_and_a_hash_like_every_other_class
    assert_html builder.number_group(:budget, input_class: %w[font-mono text-right]),
                "input.input.font-mono.text-right"
    assert_html builder.number_group(:budget, input_class: { "font-mono" => true }),
                "input.input.font-mono"
    assert_html builder.text_area_group(:synopsis, input_class: { "font-mono" => true }),
                "textarea.textarea.font-mono"
  end

  # The bug the same line used to carry, found while `input_class:` was being
  # threaded through it: `class:` was interpolated into the control's class list
  # while the `<fieldset>` read it with `class_names`, so the two halves of one
  # option disagreed about what an Array means.
  def test_class_takes_an_array_on_the_control_too_and_not_only_on_the_fieldset
    html = builder.number_group(:budget, class: %w[font-mono])

    assert_html html, "fieldset.font-mono"
    assert_html html, "input.input.font-mono"
  end

  # `class:` is not changing: two host apps depend on the two places it lands.
  def test_class_still_reaches_both_the_fieldset_and_the_control
    html = builder.number_group(:budget, label: "Monto", class: "font-mono")

    assert_html html, "fieldset.font-mono"
    assert_html html, "input.input.font-mono"
  end

  # Both spellings, one destination, on the four families that take two hashes.
  def test_html_class_is_the_same_destination_on_the_two_hash_families
    assert_html builder.select_group(:status, [], html: { class: "font-mono" }),
                "select.select.font-mono"
    assert_html builder.select_group(:status, [], input_class: "font-mono"),
                "select.select.font-mono"
    refute_html builder.select_group(:status, [], input_class: "font-mono"), "fieldset.font-mono"
  end

  # With `alt_input: true` flatpickr hides the real input and draws a second one
  # from this class list, so a class meant for the control has to be in it —
  # otherwise the only input the user sees is the one that never got it.
  def test_it_reaches_the_alt_input_flatpickr_draws
    html = builder.date_group(:release_date, alt_input: true, input_class: "font-mono").to_s
    wrapper = Nokogiri::HTML5.fragment(html).at_css("[data-datepicker-alt-input-class-value]")

    assert_includes wrapper["data-datepicker-alt-input-class-value"], "font-mono"
  end

  private

  def probed(html)
    Nokogiri::HTML5.fragment(html.to_s).css(".#{PROBE}")
  end

  def attribute_names(html)
    Nokogiri::HTML5.fragment(html.to_s).css("*").flat_map { |node| node.attributes.keys }.uniq
  end

  def live_group_helpers
    deprecated = Bali::FormBuilder::DeprecatedNames.instance_methods.map(&:to_s)

    Bali::FormBuilder.instance_methods.map(&:to_s).grep(/_group\z/) - deprecated
  end

  # ActionText's `rich_text_area` reaches for `main_app`, so this sweep needs a
  # view context with the dummy app's routes rather than a bare one.
  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end
end
