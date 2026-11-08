# frozen_string_literal: true

# For the FilterForm tests that hold under both ransack 5 and 6 (#1530).
module RansackTestHelpers
  # Runs the block as if the installed ransack were 6 (true) or 5 (false), by setting
  # RansackParamName's memo of its own detection.
  def as_ransack(insensitive)
    original = Bali::RansackParamName.case_insensitive_text?
    Bali::RansackParamName.instance_variable_set(:@case_insensitive_text, insensitive)
    yield
  ensure
    Bali::RansackParamName.instance_variable_set(:@case_insensitive_text, original)
  end

  def text(predicate) = Bali::RansackParamName.text_predicate(predicate)

  # `[attribute, operator, value]` of each condition the panel draws.
  def conditions(form)
    form.filter_groups.flat_map { |group| group[:conditions].map { |condition| condition.values_at(:attribute, :operator, :value) } }
  end
end
