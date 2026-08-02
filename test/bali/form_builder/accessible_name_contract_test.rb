# frozen_string_literal: true

require "test_helper"

# The accessibility contract every `*_field_group` owes its caller:
#
#   1. the caption names the control — a `<label for>` reaching an id that is
#      really in the document, or a `<legend>` over a group whose controls carry
#      names of their own;
#   2. nothing in the group repeats an id, not even when a second form for the
#      same model sits on the same page;
#   3. a field with an error says so on the control (`aria-invalid`) and points
#      `aria-describedby` at ids that exist.
#
# Swept over every family rather than sampled, because the whole point of
# deriving ids from `field_id` in one place is that no family can opt out.
class BaliFormBuilderAccessibleNameContractTest < FormBuilderTestCase
  # Every group helper, and how the control inside it is expected to get its
  # name. Three legitimate shapes, spelled out rather than inferred:
  #
  #   "an_id"          a `<label for>` reaching that id, which must be in the
  #                    document — the ~18 families wrapping one labelable control;
  #   :legend          a `<legend>` over a group whose several controls carry
  #                    names of their own, or a widget no `for` can reach;
  #   :wrapping_label  the control sits inside a `<label>` that contributes text,
  #                    so the implicit association names it. This is how a
  #                    checkbox and a toggle are normally labelled, and it is
  #                    why those two render no `<legend>` unless asked: a second
  #                    caption does not replace the name, it concatenates with
  #                    it, and the control read out "Indie Indie".
  GROUPS = {
    "text_field_group" => [ ->(b) { b.text_field_group(:name) }, "movie_name" ],
    "email_field_group" => [ ->(b) { b.email_field_group(:name) }, "movie_name" ],
    "url_field_group" => [ ->(b) { b.url_field_group(:name) }, "movie_name" ],
    "password_field_group" => [ ->(b) { b.password_field_group(:name) }, "movie_name" ],
    "number_field_group" => [ ->(b) { b.number_field_group(:budget) }, "movie_budget" ],
    "month_field_group" => [ ->(b) { b.month_field_group(:release_date) }, "movie_release_date" ],
    "text_area_group" => [ ->(b) { b.text_area_group(:synopsis) }, "movie_synopsis" ],
    "date_field_group" => [ ->(b) { b.date_field_group(:release_date) }, "movie_release_date" ],
    "datetime_field_group" => [ ->(b) { b.datetime_field_group(:release_date) },
                               "movie_release_date" ],
    "time_field_group" => [ ->(b) { b.time_field_group(:duration) }, "movie_duration" ],
    "currency_field_group" => [ ->(b) { b.currency_field_group(:budget) }, "movie_budget" ],
    "percentage_field_group" => [ ->(b) { b.percentage_field_group(:budget) }, "movie_budget" ],
    "search_field_group" => [ ->(b) { b.search_field_group(:name) }, "movie_name" ],
    "step_number_field_group" => [ ->(b) { b.step_number_field_group(:duration) },
                                  "movie_duration" ],
    "file_field_group" => [ ->(b) { b.file_field_group(:name) }, "movie_name" ],
    "select_group" => [ ->(b) { b.select_group(:status, [ %w[One 1] ]) }, "movie_status" ],
    "slim_select_group" => [ ->(b) { b.slim_select_group(:status, [ %w[One 1] ]) },
                            "movie_status" ],
    "time_zone_select_group" => [ ->(b) { b.time_zone_select_group(:name) }, "movie_name" ],
    "time_period_field_group" => [ ->(b) { b.time_period_field_group(:release_date, [ %w[T t] ]) },
                                  "movie_release_date_period" ],
    "range_field_group" => [ ->(b) { b.range_field_group(:rating) }, "movie_rating" ],
    "boolean_field_group" => [ ->(b) { b.boolean_field_group(:indie) }, :wrapping_label ],
    "switch_field_group" => [ ->(b) { b.switch_field_group(:indie) }, :wrapping_label ],
    "radio_field_group" => [ ->(b) { b.radio_field_group(:status, [ %w[One 1] ]) }, :legend ],
    "radio_buttons_group" => [ ->(b) { b.radio_buttons_group(:status, { a: [ %w[One 1] ] }) },
                              :legend ],
    "coordinates_polygon_field_group" => [ ->(b) { b.coordinates_polygon_field_group(:name) },
                                          :legend ],
    "block_editor_group" => [ ->(b) { b.block_editor_group(:synopsis) }, :legend ],
    "rich_text_area_group" => [ ->(b) { b.rich_text_area_group(:synopsis) }, :legend ],
    "recurrent_event_rule_field_group" => [ ->(b) { b.recurrent_event_rule_field_group(:rule) },
                                           :legend ]
  }.freeze

  # Families that render the error and help paragraphs on a control able to carry
  # the aria pair. Left out: the composites, whose control is a hidden field or a
  # client-side widget.
  DESCRIBED = {
    "text_field_group" => ->(b, o) { b.text_field_group(:name, o) },
    "text_area_group" => ->(b, o) { b.text_area_group(:name, o) },
    "select_group" => ->(b, o) { b.select_group(:name, [], {}, o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:name, [], {}, o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, nil, {}, o) },
    "boolean_field_group" => ->(b, o) { b.boolean_field_group(:name, o) },
    "switch_field_group" => ->(b, o) { b.switch_field_group(:name, o) },
    "radio_field_group" => ->(b, o) { b.radio_field_group(:name, [ %w[One 1] ], o) },
    "range_field_group" => ->(b, o) { b.range_field_group(:name, o) }
  }.freeze

  def test_every_group_caption_reaches_the_control_it_names
    unnamed = GROUPS.filter_map do |name, (render, expectation)|
      document = fragment(render.call(builder))

      case expectation
      when :wrapping_label then resolve_wrapping_label(name, document)
      when :legend then resolve_legend(name, document)
      else resolve_label_for(name, document, expectation)
      end
    end

    assert_empty unnamed, "Controls left without an accessible name:\n#{unnamed.join("\n")}"
  end

  # The check that keeps `:wrapping_label` honest. Drop the inline caption and
  # the checkbox has no name from anywhere, which is exactly the state the
  # contract exists to catch — so assert that the shape fails when the text is
  # gone, not merely that it passes when the text is there.
  def test_a_checkbox_with_no_inline_caption_and_no_legend_is_reported_as_unnamed
    document = fragment(builder.boolean_field_group(:indie, text: false))

    refute_nil resolve_wrapping_label("boolean_field_group", document),
               "A checkbox with neither an inline caption nor a legend has no accessible " \
               "name, and the contract has to say so"
  end

  # The case no preview covers and the one that breaks today: the same model
  # rendered twice on a page. Rails keeps the two apart through the index, and
  # every id Bali derives has to follow it rather than being rebuilt by hand.
  def test_two_forms_for_the_same_model_on_one_page_share_no_id
    first = indexed_builder(1)
    second = indexed_builder(2)

    duplicates = GROUPS.filter_map do |name, (render, _)|
      ids = element_ids(render.call(first)) + element_ids(render.call(second))
      repeated = ids.tally.select { |_, count| count > 1 }.keys

      "#{name}: #{repeated.inspect}" if repeated.any?
    end

    assert_empty duplicates,
                 "Ids repeated across two forms for the same model:\n#{duplicates.join("\n")}"
  end

  def test_a_single_group_never_repeats_an_id
    duplicates = GROUPS.filter_map do |name, (render, _)|
      ids = element_ids(render.call(builder))
      repeated = ids.tally.select { |_, count| count > 1 }.keys

      "#{name}: #{repeated.inspect}" if repeated.any?
    end

    assert_empty duplicates, "Ids repeated inside one group:\n#{duplicates.join("\n")}"
  end

  def test_an_invalid_field_says_so_on_the_control_and_describes_it
    invalid = DESCRIBED.filter_map do |name, render|
      document = fragment(render.call(errored_builder, help: "Keep it short"))
      control = document.at_css("[aria-invalid]")

      next "#{name}: nothing carries aria-invalid" if control.nil?
      next "#{name}: aria-invalid=#{control["aria-invalid"].inspect}" \
        if control["aria-invalid"] != "true"

      described = control["aria-describedby"].to_s.split
      next "#{name}: no aria-describedby" if described.empty?

      dangling = described.reject { |id| document.at_css("##{CSS.escape_id(id)}") }
      next "#{name}: aria-describedby names ids nothing emits: #{dangling.inspect}" if dangling.any?
      next "#{name}: the error paragraph is not among them" unless described.include?("movie_name_error")
      next "#{name}: the help paragraph is not among them" unless described.include?("movie_name_help")

      nil
    end

    assert_empty invalid, "Fields whose error is not announced:\n#{invalid.join("\n")}"
  end

  def test_a_valid_field_carries_neither_aria_invalid_nor_a_dangling_description
    leaked = DESCRIBED.filter_map do |name, render|
      document = fragment(render.call(builder, {}))

      next "#{name}: aria-invalid on a field with no error" if document.at_css("[aria-invalid]")
      next "#{name}: aria-describedby with no paragraph to name" if document.at_css("[aria-describedby]")

      nil
    end

    assert_empty leaked, "Fields describing paragraphs that are not there:\n#{leaked.join("\n")}"
  end

  private

  # Capybara's own escaping is not available on a Nokogiri fragment, and these
  # ids can carry the brackets Rails derives from a bracketed method name.
  module CSS
    def self.escape_id(id)
      id.gsub(/([^a-zA-Z0-9_-])/) { "\\#{Regexp.last_match(1)}" }
    end
  end

  def caption_in(document)
    document.at_css("label.fieldset-legend, legend.fieldset-legend")
  end

  def resolve_legend(name, document)
    caption = caption_in(document)

    return "#{name}: no caption at all" if caption.nil?
    return "#{name}: expected a <legend> for a multi-control group" if caption.name != "legend"

    nil
  end

  def resolve_label_for(name, document, control_id)
    caption = caption_in(document)

    return "#{name}: no caption at all" if caption.nil?
    return "#{name}: caption is a <legend>, so it names nothing" if caption.name == "legend"
    return "#{name}: for=#{caption["for"].inspect} but the id is #{control_id.inspect}" \
      if caption["for"] != control_id
    return "#{name}: for points at #{control_id.inspect}, which nothing emits" \
      if document.at_css("##{CSS.escape_id(control_id)}").nil?

    nil
  end

  # An implicit label association: the control is a descendant of a `<label>`,
  # and that label contributes text. Both halves matter — a `<label>` wrapping
  # a bare checkbox and nothing else names it "".
  def resolve_wrapping_label(name, document)
    control = document.at_css("input[type=checkbox]:not([type=hidden])")
    return "#{name}: no control to name" if control.nil?

    label = control.ancestors("label").first
    return "#{name}: the control is not inside a <label>" if label.nil?
    return "#{name}: the wrapping <label> contributes no text" if label.text.strip.empty?

    nil
  end

  def fragment(html)
    Nokogiri::HTML5.fragment(html.to_s)
  end

  def element_ids(html)
    fragment(html).css("[id]").map { |node| node["id"] }
  end

  def view_context
    @view_context ||= vc_test_controller.view_context
  end

  def indexed_builder(index)
    Bali::FormBuilder.new("movie", Movie.new, view_context, index: index)
  end

  def errored_builder
    movie = Movie.new
    movie.errors.add(:name, "is too long")
    Bali::FormBuilder.new("movie", movie, view_context, {})
  end

  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, view_context, {})
  end
end
