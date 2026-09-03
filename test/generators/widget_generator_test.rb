# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/bali/widget/widget_generator"

class BaliWidgetGeneratorTest < Rails::Generators::TestCase
  tests Bali::WidgetGenerator
  destination Rails.root.join("tmp/generator_test")
  setup :prepare_destination

  # THE PATTERN IS THE SUPERCLASS, not a declaration in the class body. That is
  # the whole architecture in one assertion: `--pattern list` does not write a
  # macro saying "I am a list", it inherits from the class that makes it one.
  def test_the_pattern_picks_the_base_class
    run_generator %w[LowStockItems --pattern list --size medium]

    assert_file "app/widgets/low_stock_items.rb" do |content|
      assert_match(/class LowStockItems < Bali::Widget::ListBase/, content)
      assert_match(/default_size :medium/, content)
      assert_match(/^  list do/, content)
      assert_match(/^  row do \|r\|/, content)
      assert_match(/^    r\.title :name/, content)
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

  # Each pattern scaffolds exactly the methods ITS base leaves abstract — which
  # is how a developer learns what a trend widget owes the card without reading
  # a guide. A trend needs two figures and the base computes the delta between
  # them; it has no list and no rows.
  def test_a_trend_scaffolds_the_two_figures_its_base_compares
    run_generator %w[Trending --pattern trend --size medium]

    assert_file "app/widgets/trending.rb" do |content|
      assert_match(/^  trend do \|t\|/, content)
      assert_match(/t\.current/, content)
      # Commented out: a series is optional, and a scaffolded `s.values { [] }`
      # is a declaration that silently does nothing.
      assert_match(/^  # series do \|s\|/, content)
      assert_no_match(/^  list/, content)
      assert_no_match(/^  goal /, content)
    end
  end

  def test_a_progress_scaffolds_the_ring_that_replaces_the_number
    run_generator %w[Onboarding --pattern progress --size large]

    assert_file "app/widgets/onboarding.rb" do |content|
      assert_match(/class Onboarding < Bali::Widget::ProgressBase/, content)
      assert_match(/^  goal do \|g\|/, content)
      assert_no_match(/^  trend do/, content)
    end
  end

  # `ValueBase` offers `small` alone, so the generator writes no `supports` at
  # all: restating what the base already says would be a second place to keep
  # one fact, free to drift from it.
  def test_a_value_widget_inherits_its_sizes_rather_than_restating_them
    run_generator %w[Budget --pattern value --size small]

    assert_file "app/widgets/budget.rb" do |content|
      assert_match(/^  value \{/, content)
      assert_no_match(/^  list/, content)
      assert_no_match(/supports/, content)
    end
  end

  def test_supports_is_written_only_when_it_overrides_the_base
    run_generator %w[Budget --pattern value --size medium --supports small medium]

    assert_file "app/widgets/budget.rb" do |content|
      assert_match(/supports :small, :medium/, content)
    end
  end

  # A `value` widget at `medium` would be rejected by `supports` itself at
  # class-definition time — the default must be a size a user can choose. The
  # generator refuses first, where the message can name the flag to fix.
  #
  # The message is not asserted: Thor catches `Thor::Error` and prints it to
  # STDERR, which `run_generator` does not capture. What matters is that nothing
  # half-made is written.
  def test_refuses_a_default_size_the_pattern_does_not_offer
    run_generator %w[Budget --pattern value --size large]

    assert_no_file "app/widgets/budget.rb"
  end

  def test_refuses_a_pattern_that_is_not_one_of_the_four
    run_generator %w[Budget --pattern metric]

    assert_no_file "app/widgets/budget.rb"
  end

  def test_generates_a_test
    run_generator %w[LowStockItems --size large]

    assert_file "test/widgets/low_stock_items_test.rb" do |content|
      assert_match(/assert_equal :large, LowStockItems\.default_size/, content)
      assert_match(/assert_kind_of Integer, widget\.count/, content)
    end
  end

  # THE SCAFFOLD MUST CALL AN API THAT EXISTS. `test/widgets/` does not exist in
  # this repo, so a generated widget test is never executed here — the assertion
  # above only greps the file. That is how the scaffold went on calling
  # `widget.size` after size moved to `Bali::Widget::Placement`: every generated
  # test NoMethodError'd on its first line, which is the first thing a host runs.
  #
  # Names the removed method rather than the current one, so this fails if it
  # ever comes back rather than merely drifting alongside it.
  #
  # READ FROM THE TEMPLATE, so this covers every pattern branch. Inspecting
  # generated output would only ever cover the preamble plus whichever pattern
  # the test happened to generate.
  def test_the_scaffolded_test_does_not_call_a_removed_api
    template = Bali::Engine.root.join("lib/generators/bali/widget/templates/widget_test.rb.tt").read

    refute_match(/widget\.size\b/, template,
                 "a widget has no `size` — the same class is small for one owner and large " \
                 "for another, which is what `Bali::Widget::Placement` is for")
  end

  # Every pattern's scaffold asserts something. `check` was scaffolding an empty
  # method body under a comment claiming to cover the whole interface.
  #
  # READ FROM THE TEMPLATE, not by generating five widgets: each run also inserts
  # into the locale files, and five runs in one test collide on them.
  def test_every_pattern_scaffolds_a_load_assertion
    template = Bali::Engine.root.join("lib/generators/bali/widget/templates/widget_test.rb.tt").read
    body = template[/def test_it_loads(.*?)\n  end/m, 1]

    %w[value list trend progress check].each do |pattern|
      branch = body[/pattern == '#{pattern}' -%>(.*?)<%/m, 1]

      assert_match(/assert/, branch.to_s, "`--pattern #{pattern}` scaffolds no assertion")
    end
  end

  # the generator validates the pair before writing the file so a typo is a boot
  # failure. The generator refuses earlier still — nothing is written at all.
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
