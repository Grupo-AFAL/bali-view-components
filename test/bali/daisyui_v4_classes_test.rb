# frozen_string_literal: true

require "test_helper"

# daisyUI 5 defines none of these classes, so they paint nothing; all they still do is give a host
# selector something to hold on to (#903). `select-bordered` is not among them: Bali's own
# `slim_select.css` defines it.
class BaliDaisyuiV4ClassesTest < ActiveSupport::TestCase
  DAISYUI_V4_CLASSES = %w[label-text label-text-alt input-bordered textarea-bordered form-control].freeze
  V4_CLASS = /(?<![\w-])(?:#{DAISYUI_V4_CLASSES.join('|')})(?![\w-])/

  def test_no_template_or_script_writes_a_daisyui_4_class
    files = Dir[Bali::Engine.root.join("app/**/*.{erb,rb,js}").to_s]
    assert_operator(files.size, :>, 500) # sanity: the glob found the components and their previews

    offenders = files.flat_map do |file|
      File.readlines(file).each_with_index.filter_map do |line, index|
        "#{file.delete_prefix("#{Bali::Engine.root}/")}:#{index + 1}" if line.match?(V4_CLASS)
      end
    end

    assert_empty(offenders, "daisyUI 5 defines none of #{DAISYUI_V4_CLASSES.join(', ')}")
  end
end
