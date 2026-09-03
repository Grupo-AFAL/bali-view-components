# frozen_string_literal: true

require "test_helper"

# `input_name:` / `input_id:` are the non-model escape hatch of #547: on a
# `form_with url:` there is no object for Rails to derive a name from, so one
# field at a time can be told what to call itself.
#
# Until #1111 the pair was read by three families and by nobody else. Everywhere
# else it was not a Bali option at all — it fell through to Rails, which forwards
# what it does not recognise, and the input came out carrying
# `input_name="import[file]"` while still submitting under the name Rails had
# derived. `params.require(:import)` then 400'd, Turbo swallowed the response and
# the screen sat there unchanged. Measured on eight of the fourteen group helpers.
#
# So the contract has two outcomes and every helper has to be in one of them by
# name: the option renames the control, or it renames nothing — and in neither
# case does it reach the DOM.
class BaliFormBuilderInputNameOptionTest < FormBuilderTestCase
  # Families whose control is a native named input, so the escape hatch has
  # somewhere to land.
  RENAMES = {
    "text_group" => ->(b, o) { b.text_group(:name, **o) },
    "text_field" => ->(b, o) { b.text_field(:name, **o) },
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
    "search_group" => ->(b, o) { b.search_group(:name, **o) },
    "currency_group" => ->(b, o) { b.currency_group(:budget, **o) },
    "percentage_group" => ->(b, o) { b.percentage_group(:budget, **o) },
    "numeric_group" => ->(b, o) { b.numeric_group(:budget, **o) },
    "step_number_group" => ->(b, o) { b.step_number_group(:duration, **o) },
    "range_group" => ->(b, o) { b.range_group(:rating, **o) },
    "boolean_group" => ->(b, o) { b.boolean_group(:indie, **o) },
    "switch_group" => ->(b, o) { b.switch_group(:indie, **o) },
    "select_group" => ->(b, o) { b.select_group(:status, [], **o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:status, [], **o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, **o) },
    # A widget over a hidden field, but the hidden field is a real named control
    # and it is the one the form submits.
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "rich_text_group" => ->(b, o) { b.rich_text_group(:synopsis, **o) },
    # ActionText's Trix helper, and a plain named hidden field underneath.
    "rich_text_area_group" => ->(b, o) { b.rich_text_area_group(:synopsis, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    # Every radio in a group shares one name, which is exactly what the hatch is
    # for. `input_id:` is the half it cannot take — see the ids test below.
    "radio_group" => ->(b, o) { b.radio_group(:status, [ %w[One 1] ], **o) }
  }.freeze

  # Everything with no single control to rename.
  #
  # `submit_group` / `submit_field`: a submit button's `name` is not the field's,
  # it is which button was pressed, and no non-model form needs a hatch for that.
  #
  # `radio_buttons_group`: its per-input attributes travel in the `radios:` hash,
  # one entry per group of buttons, so there is no one name for the option to set.
  #
  # `direct_upload_group` and `recurrent_event_rule_group` render their own
  # multi-input widgets; neither has a single name to move.
  RENAMES_NOTHING = {
    "submit_group" => ->(b, o) { b.submit_group("Save", **o) },
    "submit_field" => ->(b, o) { b.submit_field("Save", **o) },
    "radio_buttons_group" => ->(b, o) { b.radio_buttons_group(:status, { a: [ %w[One 1] ] }, **o) },
    "direct_upload_group" => ->(b, o) { b.direct_upload_group(:name, **o) },
    "recurrent_event_rule_group" => ->(b, o) { b.recurrent_event_rule_group(:rule, **o) }
  }.freeze

  # Renders a button and a container for nested records, never a control of its
  # own, and needs a real association to render at all. Named here rather than
  # left out silently, so the coverage check below stays a check.
  UNSWEPT_GROUPS = %w[dynamic_fields_group].freeze

  NEW_NAME = "import[file]"
  NEW_ID = "import_file"

  def test_every_group_helper_is_covered_by_this_sweep
    swept = RENAMES.keys + RENAMES_NOTHING.keys + UNSWEPT_GROUPS
    uncovered = live_group_helpers - swept

    assert_empty uncovered,
                 "Group helpers with no `input_name:` expectation, so nothing says whether " \
                 "the escape hatch works there: #{uncovered.sort.inspect}. " \
                 "Add each to RENAMES or RENAMES_NOTHING."
  end

  def test_input_name_renames_the_control
    missing = RENAMES.filter_map do |name, render|
      names = control_names(render.call(builder, { input_name: NEW_NAME }))
      "#{name}: #{names.inspect}" unless names.include?(NEW_NAME)
    end

    assert_empty missing, "`input_name:` never reached a control:\n#{missing.join("\n")}"
  end

  # The half of the report that cost the weeks: the option looked accepted and the
  # element kept the name Rails derived from the form object.
  def test_file_group_submits_under_the_name_it_was_given
    html = builder.file_group(:file, input_name: NEW_NAME, accept: ".csv")

    assert_equal [ NEW_NAME ], control_names(html)
    assert_html html, "input[type=file][accept='.csv']", visible: false
  end

  def test_input_id_renames_the_control_and_the_caption_follows_it
    html = builder.text_group(:name, input_id: NEW_ID, label: "File")

    assert_html html, "input##{NEW_ID}"
    assert_html html, "label[for=#{NEW_ID}]"
  end

  # `input_id:` is the half of the hatch four of those families cannot take, each
  # for a reason of its own. It is dropped rather than honoured wrongly — and,
  # since #1111, dropped rather than painted on the element.
  #
  # `radio_group`: Rails suffixes each radio's id with its own value, so one id
  # for the group would be N elements answering to the same name.
  #
  # `block_editor_group` / `rich_text_group`: the hidden input's id is the
  # component's own, derived alongside the editor container it has to match.
  #
  # `coordinates_polygon_group` / `time_period_group`: a hidden input is not
  # labelable, and their caption is a `<legend>` pointing at nothing (the period
  # picker's `for` names its visible select, which is not this field).
  IGNORES_INPUT_ID = {
    "radio_group" => ->(b, o) { b.radio_group(:status, [ %w[One 1], %w[Two 2] ], **o) },
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "rich_text_group" => ->(b, o) { b.rich_text_group(:synopsis, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) }
  }.freeze

  def test_the_families_that_cannot_take_input_id_keep_their_own_ids
    changed = IGNORES_INPUT_ID.filter_map do |name, render|
      ids = element_ids(render.call(builder, { input_id: NEW_ID }), "*")
      "#{name}: #{ids.compact.inspect}" if ids.include?(NEW_ID)
    end

    assert_empty changed,
                 "A helper that cannot honour `input_id:` took it anyway:\n#{changed.join("\n")}"
  end

  # The half of `radio_group`'s story worth pinning: the per-value ids Rails
  # derives are still there, which is what the caption of each button points at.
  def test_radio_group_keeps_its_per_value_ids
    html = builder.radio_group(:status, [ %w[One 1], %w[Two 2] ], input_id: NEW_ID)

    assert_equal %w[movie_status_1 movie_status_2], element_ids(html, "input[type=radio]")
  end

  # The same hole, spelled the way the report spelled it. On the families that take
  # a second `html:` hash, a plain top-level `name:` was handed to Rails' `select` as
  # a field option — which does not read it — and vanished; and a top-level `id:`
  # vanished with it while the caption's `for` went on pointing at it, so the
  # `<label for>` named nothing in the document and the control had no accessible
  # name at all.
  TWO_HASH_FAMILIES = {
    "select_group" => ->(b, o) { b.select_group(:status, [ %w[One 1] ], **o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:status, [ %w[One 1] ], **o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, **o) }
  }.freeze

  def test_a_plain_name_at_the_top_level_reaches_the_element
    missing = TWO_HASH_FAMILIES.filter_map do |name, render|
      names = control_names(render.call(builder, { name: NEW_NAME }))
      "#{name}: #{names.inspect}" unless names.include?(NEW_NAME)
    end

    assert_empty missing, "A top-level `name:` never reached the control:\n#{missing.join("\n")}"
  end

  def test_the_caption_and_the_control_agree_on_a_plain_top_level_id
    mismatched = TWO_HASH_FAMILIES.filter_map do |name, render|
      html = render.call(builder, { id: NEW_ID, label: "Status" })
      fragment = Nokogiri::HTML5.fragment(html.to_s)
      control = fragment.at_css("select")
      caption = fragment.at_css("label[for]")

      unless control && caption && control["id"] == caption["for"]
        "#{name}: control id #{control&.[]("id").inspect}, label for #{caption&.[]("for").inspect}"
      end
    end

    assert_empty mismatched,
                 "A `<label for>` pointing at an id the control does not carry:\n" \
                 "#{mismatched.join("\n")}"
  end

  # The other door into the same accessibility failure, and the one the PR review
  # caught: `html: { id: }` is the route this guide calls "the most specific and the
  # one that wins", and it reached the `<select>` while the caption went on pointing
  # at Rails' derived id. `control_id` reads the group hash, and the group hash is
  # built out of WRAPPER_OPTIONS, which cannot hold `:id` — RESERVED_OPTIONS is built
  # from it and would strip the id off every element in the builder (#1113).
  def test_the_caption_and_the_control_agree_on_an_id_written_in_the_html_hash
    mismatched = TWO_HASH_FAMILIES.filter_map do |name, render|
      html = render.call(builder, { label: "Status", html: { id: NEW_ID } })
      fragment = Nokogiri::HTML5.fragment(html.to_s)
      control = fragment.at_css("select")
      caption = fragment.at_css("label[for]")

      unless control && caption && control["id"] == caption["for"] && control["id"] == NEW_ID
        "#{name}: control id #{control&.[]("id").inspect}, label for #{caption&.[]("for").inspect}"
      end
    end

    assert_empty mismatched,
                 "A `<label for>` pointing at an id the control does not carry:\n" \
                 "#{mismatched.join("\n")}"
  end

  # Same precedence for the caption as for the element: `apply_input_name_options`
  # only fills an id `html:` did not already set, so the caption has to follow
  # `html:` too or the two disagree again.
  def test_the_html_hash_wins_over_a_top_level_id
    html = builder.select_group(:status, [ %w[One 1] ], id: NEW_ID, label: "Status",
                                                        html: { id: "html_id" })
    fragment = Nokogiri::HTML5.fragment(html.to_s)

    assert_equal "html_id", fragment.at_css("select")["id"]
    assert_equal "html_id", fragment.at_css("label[for]")["for"]
  end

  # `control_id:` is the key that names the caption's target, so it still outranks
  # both — including `control_id: false`, which is how a group holding several
  # controls keeps a `<legend>` that points at nothing.
  def test_an_explicit_control_id_still_wins_over_both_hashes
    html = builder.select_group(:status, [ %w[One 1] ], label: "Status",
                                                        control_id: "caption_target",
                                                        html: { id: NEW_ID })
    fragment = Nokogiri::HTML5.fragment(html.to_s)

    assert_equal NEW_ID, fragment.at_css("select")["id"]
    assert_equal "caption_target", fragment.at_css("label[for]")["for"]
  end

  def test_a_legend_is_still_reachable_through_control_id_false
    html = builder.select_group(:status, [ %w[One 1] ], label: "Status", control_id: false,
                                                        html: { id: NEW_ID })

    assert_html html, "legend", text: "Status"
    refute_html html, "label[for]"
  end

  # `multiple` is what makes a control submit a list, and Rails spells that in the
  # name — but `add_default_name_and_id` only appends the `[]` to a name it derived
  # itself, so a name this hatch supplies never got one. Three chosen files arrived
  # as one, silently (#1113).
  # `multiple:` reaches the element by a different route per family, so each lambda
  # writes it where that family reads it: SlimSelect's `<select>` always carries a
  # `multiple` key of its own, which is why a top-level one never gets there.
  MULTIPLE_FAMILIES = {
    "file_group" => ->(b, o) { b.file_group(:name, **o) },
    "select_group" => ->(b, o) { b.select_group(:status, [ %w[One 1] ], **o) },
    "slim_select_group" => lambda { |b, o|
      b.slim_select_group(:status, [ %w[One 1] ], html: o.slice(:multiple),
                                                  **o.except(:multiple))
    }
  }.freeze

  def test_a_renamed_multiple_control_still_submits_an_array
    missing = MULTIPLE_FAMILIES.filter_map do |name, render|
      names = control_names(render.call(builder, { multiple: true, input_name: NEW_NAME }))
      "#{name}: #{names.inspect}" unless names.uniq == [ "#{NEW_NAME}[]" ]
    end

    assert_empty missing,
                 "A multiple control renamed by the hatch lost the `[]` that makes it " \
                 "an array:\n#{missing.join("\n")}"
  end

  def test_a_name_that_already_ends_in_brackets_is_not_doubled
    html = builder.file_group(:name, multiple: true, input_name: "#{NEW_NAME}[]")

    assert_equal [ "#{NEW_NAME}[]" ], control_names(html).uniq
  end

  def test_a_control_that_is_not_multiple_keeps_the_bare_name
    kept = MULTIPLE_FAMILIES.filter_map do |name, render|
      names = control_names(render.call(builder, { input_name: NEW_NAME }))
      "#{name}: #{names.inspect}" unless names.uniq == [ NEW_NAME ]
    end

    assert_empty kept, "A single-value control was named as an array:\n#{kept.join("\n")}"
  end

  # The suffix follows the element, not the call site. SlimSelect's `<select>` always
  # carries a `multiple` key of its own, so Rails never copies a top-level
  # `multiple: true` onto it and the control is not multiple however the option was
  # written — naming it as an array would be the same silent mis-submission the other
  # way round.
  def test_the_suffix_follows_the_element_and_not_the_option
    html = builder.slim_select_group(:status, [ %w[One 1] ], multiple: true,
                                                             input_name: NEW_NAME)
    select = Nokogiri::HTML5.fragment(html.to_s).at_css("select")

    assert_nil select["multiple"]
    assert_equal NEW_NAME, select["name"]
  end

  # `html:` is still the more specific hash and still wins.
  def test_the_html_hash_wins_over_a_top_level_name
    html = builder.select_group(:status, [ %w[One 1] ], name: NEW_NAME, html: { name: "html[name]" })

    assert_equal [ "html[name]" ], control_names(html)
  end

  def test_an_explicit_name_still_wins_over_the_escape_hatch
    html = builder.text_field(:name, input_name: NEW_NAME, name: "explicit[name]")

    assert_equal [ "explicit[name]" ], control_names(html)
  end

  def test_neither_option_reaches_the_dom_as_an_attribute
    leaks = RENAMES.merge(RENAMES_NOTHING).filter_map do |name, render|
      html = render.call(builder, { input_name: NEW_NAME, input_id: NEW_ID })
      found = attribute_names(html) & %w[input_name input-name input_id input-id]
      "#{name}: #{found.sort.inspect}" if found.any?
    end

    assert_empty leaks, "The escape hatch rendered as an HTML attribute:\n#{leaks.join("\n")}"
  end

  def test_the_families_that_cannot_rename_leave_the_derived_name_alone
    renamed = RENAMES_NOTHING.filter_map do |name, render|
      names = control_names(render.call(builder, { input_name: NEW_NAME }))
      "#{name}: #{names.inspect}" if names.include?(NEW_NAME)
    end

    assert_empty renamed,
                 "A helper with no single control to rename renamed one anyway:\n" \
                 "#{renamed.join("\n")}"
  end

  private

  def control_names(html)
    Nokogiri::HTML5.fragment(html.to_s).css("[name]").map { |node| node["name"] }
  end

  def element_ids(html, selector)
    Nokogiri::HTML5.fragment(html.to_s).css(selector).map { |node| node["id"] }
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
