# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/bali/widget/widget_generator"

class BaliWidgetGeneratorTest < Rails::Generators::TestCase
  tests Bali::WidgetGenerator
  destination Rails.root.join("tmp/generator_test")
  setup :prepare_destination

  def test_generates_the_widget_at_its_declared_size
    run_generator %w[LowStockItems --size medium]

    assert_file "app/widgets/low_stock_items.rb" do |content|
      assert_match(/class LowStockItems < Bali::Widget::Base/, content)
      assert_match(/sized :medium/, content)
      # The block form, so a generated widget does not model the invisible
      # template method the `#row` contract used to be.
      assert_match(/list_from\(scope, view_all_path: nil\) do \|record\|/, content)
    end
  end

  # The four locale keys are the reason the generator exists: a host otherwise
  # discovers them from prose and forgets one — `description` especially, which
  # is only ever seen in a picker.
  def test_stubs_every_locale_key_the_card_and_picker_read
    run_generator %w[LowStockItems]

    assert_file "config/locales/widgets.en.yml" do |content|
      %w[title short_title description empty].each { |key| assert_match(/#{key}:/, content) }
      assert_match(/low_stock_items:/, content)
    end
  end

  def test_generates_a_test
    run_generator %w[LowStockItems --size large]

    assert_file "test/widgets/low_stock_items_test.rb" do |content|
      assert_match(/assert_equal :large, widget.size/, content)
    end
  end

  # `sized` is validated at class-definition time so a typo is a boot failure —
  # the generator refuses earlier still, where the message can name the options.
  # `sized` is validated at class-definition time so a typo is a boot failure.
  # The generator refuses earlier still — nothing is written at all.
  #
  # The message itself is not asserted here: Thor catches `Thor::Error` and
  # prints it to STDERR, which `run_generator` does not capture. What matters
  # is that a bad size produces no half-made widget.
  def test_refuses_a_size_that_is_not_in_the_vocabulary
    run_generator %w[LowStockItems --size enormous]

    assert_no_file "app/widgets/low_stock_items.rb"
    assert_no_file "config/locales/widgets.en.yml"
  end

  def test_skips_what_it_is_told_to_skip
    run_generator %w[LowStockItems --skip-test --skip-locales]

    assert_file "app/widgets/low_stock_items.rb"
    assert_no_file "test/widgets/low_stock_items_test.rb"
    assert_no_file "config/locales/widgets.en.yml"
  end
end
