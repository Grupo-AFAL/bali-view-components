# frozen_string_literal: true

require "test_helper"

# `control_class:` classes the box Bali renders around the control — the
# `.control` div on most families, the `.join` when addons replace it. It is the
# option that lets a call site reach the input without also reaching the
# `<fieldset>`, which plain `class:` always does.
#
# It was reserved from the start and honoured by whichever families happened to
# render a `.control` div. On the ones that render a different box, or none, it
# was dropped without a trace: `currency_group :amount, control_class: "font-mono"`
# — the exact call in #1147 — built its `<div class="join w-full">` and threw the
# class away. That is the failure #1111 exists to keep out of this builder: an
# option the call site spells correctly, that does nothing, and says nothing.
#
# So the contract has two outcomes and every family has to be in one of them by
# name: the class lands on the box around the control, or the family renders no
# box and the class lands nowhere at all.
class BaliFormBuilderControlClassOptionTest < FormBuilderTestCase
  PROBE = "probe-control-box"

  # Elements that count as "the control" for the purpose of "the box wraps it".
  CONTROLS = "input, select, textarea, trix-editor"

  # Families that render a box around their control. `.control` for most of
  # them; `.join` for the three whose addon replaces it.
  WRAPS = {
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
    "file_group" => ->(b, o) { b.file_group(:name, **o) },
    "numeric_group" => ->(b, o) { b.numeric_group(:budget, **o) },
    "step_number_group" => ->(b, o) { b.step_number_group(:duration, **o) },
    "select_group" => ->(b, o) { b.select_group(:status, [], **o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:status, [], **o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, **o) },
    "radio_group" => ->(b, o) { b.radio_group(:status, [ %w[One 1] ], **o) },
    "radio_buttons_group" => ->(b, o) { b.radio_buttons_group(:status, { a: [ %w[One 1] ] }, **o) },
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "rich_text_group" => ->(b, o) { b.rich_text_group(:synopsis, **o) },
    "rich_text_area_group" => ->(b, o) { b.rich_text_area_group(:synopsis, **o) },
    # The three whose box is the `.join` an addon builds, not a `.control` div.
    "search_group" => ->(b, o) { b.search_group(:name, **o) },
    "currency_group" => ->(b, o) { b.currency_group(:budget, **o) },
    "percentage_group" => ->(b, o) { b.percentage_group(:budget, **o) }
  }.freeze

  # Families that render no box of their own around the control, so there is no
  # element the option could have landed on. Each is here for a measured reason,
  # and each has another way to say the same thing:
  #
  # `range_group`: its `<input class="range">` hangs straight off the
  # `<fieldset>`. `boolean_group` / `switch_group`: the control sits inside the
  # `<label class="label cursor-pointer">` that carries its inline caption, and
  # that label is already addressable — `label_options: { class: ... }`. On all
  # three, `class:` reaches the control itself (as well as the fieldset).
  #
  # `coordinates_polygon_group`, `recurrent_event_rule_group`,
  # `direct_upload_group` and `time_period_group` render a whole widget rather
  # than a control in a box; the `.control` a `time_period_group` contains
  # belongs to the date field nested inside it, not to the group.
  #
  # `submit_group` is the actions row: no control, no caption, no box.
  NO_BOX = {
    "range_group" => ->(b, o) { b.range_group(:rating, **o) },
    "boolean_group" => ->(b, o) { b.boolean_group(:indie, **o) },
    "switch_group" => ->(b, o) { b.switch_group(:indie, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "recurrent_event_rule_group" => ->(b, o) { b.recurrent_event_rule_group(:rule, **o) },
    "direct_upload_group" => ->(b, o) { b.direct_upload_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    "submit_group" => ->(b, o) { b.submit_group("Save", **o) }
  }.freeze

  # The third camp, and the only member of it: `dynamic_fields_group` renders a
  # button and a container for nested records, never a control of its own, and
  # needs a real association to render at all. Named here rather than left out
  # silently, so the coverage check below stays a check — but it is unswept, not
  # declared: nothing here says what `control_class:` does inside it.
  UNSWEPT_GROUPS = %w[dynamic_fields_group].freeze

  def test_every_group_helper_is_covered_by_this_sweep
    swept = WRAPS.keys + NO_BOX.keys + UNSWEPT_GROUPS
    uncovered = live_group_helpers - swept

    assert_empty uncovered,
                 "Group helpers with no `control_class:` expectation, so nothing says " \
                 "whether the option does anything there: #{uncovered.sort.inspect}. " \
                 "Add each to WRAPS or NO_BOX."
  end

  def test_control_class_lands_on_the_box_around_the_control
    missing = WRAPS.filter_map do |name, render|
      box = boxes(render.call(builder, { control_class: PROBE, label: "L" })).first
      next "#{name}: the class reached no element" if box.nil?

      "#{name}: <#{box.name} class=#{box['class'].inspect}> wraps no control" if
        box.css(CONTROLS).empty?
    end

    assert_empty missing, "`control_class:` never reached the box:\n#{missing.join("\n")}"
  end

  # One box, not two: with a counter the join goes *inside* a `.control` div, and
  # the class has to pick one of them.
  def test_the_class_lands_exactly_once
    twice = (WRAPS.keys + NO_BOX.keys).filter_map do |name|
      render = WRAPS[name] || NO_BOX[name]
      count = boxes(render.call(builder, { control_class: PROBE, label: "L" })).size
      "#{name}: #{count}" if count > 1
    end

    assert_empty twice, "`control_class:` landed on more than one element:\n#{twice.join("\n")}"
  end

  def test_the_families_with_no_box_render_the_class_nowhere
    landed = NO_BOX.filter_map do |name, render|
      html = render.call(builder, { control_class: PROBE, label: "L" })
      found = boxes(html).map { |node| "#{node.name}.#{node['class']}" }
      "#{name}: #{found.inspect}" if found.any?
    end

    assert_empty landed,
                 "A family with no box around its control took `control_class:` anyway, " \
                 "so this sweep no longer describes it:\n#{landed.join("\n")}"
  end

  def test_the_option_never_reaches_the_dom_as_an_attribute
    leaks = WRAPS.merge(NO_BOX).filter_map do |name, render|
      html = render.call(builder, { control_class: PROBE, label: "L" }).to_s
      "#{name}" if html.include?("control_class") || html.include?("control-class")
    end

    assert_empty leaks, "`control_class:` rendered as an HTML attribute:\n#{leaks.join("\n")}"
  end

  # The addon families are the ones #1147 measured, and the box they own is the
  # join — which any family gets the moment it is given an addon.
  def test_an_addon_moves_the_box_and_the_class_follows_it
    html = builder.text_group(:name, addon_left: "$", control_class: PROBE)

    assert_html html, "div.join.#{PROBE} > input.input"
    refute_html html, "div.control"
  end

  # With a counter the join is nested in a `.control` div, which is the outer box
  # again — so that is the one carrying the class.
  def test_a_counter_keeps_the_box_on_the_control_div
    html = builder.text_group(:name, addon_left: "$", char_counter: { max: 10 },
                                     control_class: PROBE)

    assert_html html, "div.control.#{PROBE} > div.join > input.input"
  end

  def test_the_class_stays_off_the_fieldset
    html = builder.number_group(:budget, label: "Monto", control_class: "font-mono")

    assert_html html, "div.control.font-mono > input.input"
    refute_html html, "fieldset.font-mono"
    refute_html html, "input.font-mono"
  end

  # `class_names`, not interpolation: the same spelling the `<fieldset>` has
  # always accepted.
  #
  # The date families are in here by name because they were the half this
  # contract missed the first time round: they prepend their own `w-full` to the
  # option, and did it with `Array#join`, so a hash arrived as
  # `class="control w-full {&quot;font-mono&quot; =&gt; true}"` — the same defect
  # on a second line, three families wide, while the docs promised otherwise.
  def test_the_option_takes_an_array_and_a_hash_like_every_other_class
    assert_html builder.number_group(:budget, control_class: %w[font-mono max-w-32]),
                "div.control.font-mono.max-w-32"
    assert_html builder.number_group(:budget, control_class: { "font-mono" => true }),
                "div.control.font-mono"
    assert_html builder.date_group(:release_date, control_class: { "font-mono" => true }),
                "div.control.w-full.font-mono"
    assert_html builder.datetime_group(:release_date, control_class: %w[font-mono]),
                "div.control.w-full.font-mono"
    assert_html builder.time_group(:duration, control_class: { "font-mono" => true }),
                "div.control.w-full.font-mono"
  end

  # `radio_buttons_group` builds the same class list in a file of its own, and it
  # concatenated by hand too.
  def test_the_radio_buttons_group_box_takes_the_same_spellings
    assert_html builder.radio_buttons_group(:status, { a: [ %w[One 1] ] },
                                            control_class: { "font-mono" => true }),
                "div.radio-buttons-group.font-mono"
    assert_html builder.radio_buttons_group(:status, { a: [ %w[One 1] ] },
                                            control_class: %w[font-mono]),
                "div.radio-buttons-group.font-mono"
  end

  # `control_data:` travels with `control_class:` and lands on the same box. It
  # was dropped in the same place and is asserted here so the pair cannot drift.
  def test_control_data_lands_on_the_box_too
    assert_html builder.text_group(:name, addon_left: "$", control_data: { foo: "bar" }),
                "div.join[data-foo='bar']"
    assert_html builder.text_group(:name, control_data: { foo: "bar" }),
                "div.control[data-foo='bar']"
  end

  # A textarea with `auto_grow:` and an addon: the `textarea` controller has to
  # sit on an element containing both the control and the counter, which is the
  # box. Until the box became the join, that meant nothing carried it and
  # auto-grow was a silent no-op on exactly this combination. Declared here
  # because it is the one behaviour change in #1147 that is not just a class.
  def test_an_addon_no_longer_swallows_the_auto_grow_controller
    html = builder.text_area_group(:synopsis, auto_grow: true, addon_left: "$")

    assert_html html, "div.join[data-controller='textarea'][data-textarea-auto-grow-value='true']"
    assert_html html, "div.join > textarea[data-textarea-target='input']"
  end

  # `addon_class:` is NOT the general "class the addons" option the box's own
  # docs used to imply. Only `search_group` builds an addon out of it; the symbol
  # `currency_group` and `percentage_group` render carries Bali's own
  # `ADDON_CLASSES`, and an addon written at the call site is markup the call
  # site classes itself. Asserted so the guide cannot drift back.
  def test_addon_class_is_the_search_button_and_nothing_else
    assert_html builder.search_group(:name, addon_class: "btn btn-primary"),
                "button.btn.btn-primary"
    refute_html builder.currency_group(:budget, addon_class: "probe-addon"),
                ".probe-addon"
    refute_html builder.percentage_group(:budget, addon_class: "probe-addon"),
                ".probe-addon"
  end

  # `step_number_group` is the one family where the box does not wrap everything
  # the field renders: its `<div class="join">` holds the two step buttons and
  # the `.control` between them, so `control_class:` reaches the input's box and
  # not the buttons. Declared rather than fixed — the join is the stepper's, and
  # `button_class:` is what classes the buttons.
  def test_the_step_number_box_holds_the_input_and_not_the_buttons
    html = builder.step_number_group(:duration, control_class: PROBE)

    assert_html html, "div.join > div.control.#{PROBE} > input"
    refute_html html, "div.control.#{PROBE} button"
  end

  # The other half of #1147, and the reason `class:` was left alone: two host
  # apps depend on the two places it lands.
  def test_class_still_reaches_both_the_fieldset_and_the_control
    html = builder.number_group(:budget, label: "Monto", class: "font-mono")

    assert_html html, "fieldset.font-mono"
    assert_html html, "input.input.font-mono"
  end

  private

  def boxes(html)
    Nokogiri::HTML5.fragment(html.to_s).css(".#{PROBE}")
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
