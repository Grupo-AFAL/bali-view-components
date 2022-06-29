# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#step_number_field_group' do
    it 'renders an input' do
      expect(builder.step_number_field_group(:duration)).to include(
        '<div id="field-duration" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_duration">Duration</label>'\
        '<div class="field has-addons" data-controller="step-number-input">'\
        '<div class="control"><a class="button" data-action="step-number-input#subtract" '\
        'data-step-number-input-target="subtract" title="subtract" href="">'\
        "<span class=\"icon-component icon\">\n        <svg viewBox=\"0 0 14 2\" "\
        "class=\"svg-inline\" fill=\"none\">\n          <path d=\"M0.599609 0H13.3996V1.60001H0."\
        "599609V0Z\" fill=\"currentColor\"/>\n        </svg>\n      </span></a></div><div "\
        'class="control"><div class="control "><input data-step-number-input-target="input"'\
        ' class="input " type="number" value="2022-06-29 00:00:00" name="movie[duration]"'\
        ' id="movie_duration" /></div></div><div class="control"><a class="button" '\
        'data-action="step-number-input#add" data-step-number-input-target="add" '\
        "title=\"add\" href=\"\"><span class=\"icon-component icon\">\n        <svg "\
        "viewBox=\"0 0 448 512\" class=\"svg-inline\">\n          <path fill=\"currentColor\"\n "\
        '           d="M416 208H272V64c0-17.67-14.33-32-32-32h-32c-17.67 0-32 14.33-32 32v144H3'\
        '2c-17.67 0-32 14.33-32 32v32c0 17.67 14.33 32 32 32h144v144c0 17.67 14.33 32 32 32h32c1'\
        "7.67 0 32-14.33 32-32V304h144c17.67 0 32-14.33 32-32v-32c0-17.67-14.33-32-32-32z\"\n   "\
        "         class=\"\"></path>\n        </svg>\n      </span></a></div></div></div>"
      )
    end
  end

  describe '#step_number_field' do
    it 'renders an input' do
      expect(builder.step_number_field(:duration)).to include(
        '<div class="field has-addons" data-controller="step-number-input">'\
        '<div class="control"><a class="button" data-action="step-number-input#subtract"'\
        ' data-step-number-input-target="subtract" title="subtract" href="">'\
        "<span class=\"icon-component icon\">\n        <svg viewBox=\"0 0 14 2\" "\
        "class=\"svg-inline\" fill=\"none\">\n          <path d=\"M0.599609 0H13.3996V1.60001H"\
        "0.599609V0Z\" fill=\"currentColor\"/>\n        </svg>\n      </span></a></div><div "\
        'class="control"><div class="control "><input data-step-number-input-target'\
        '="input" class="input " type="number" value="2022-06-29 00:00:00" '\
        'name="movie[duration]" id="movie_duration" /></div></div><div class="control">'\
        '<a class="button" data-action="step-number-input#add" data-step-number-input-'\
        "target=\"add\" title=\"add\" href=\"\"><span class=\"icon-component icon\">\n        "\
        "<svg viewBox=\"0 0 448 512\" class=\"svg-inline\">\n          "\
        "<path fill=\"currentColor\"\n            d=\"M416 208H272V64c0-17.67-14.33-32-32-32h-"\
        '32c-17.67 0-32 14.33-32 32v144H32c-17.67 0-32 14.33-32 32v32c0 17.67 14.33 32 32 32h1'\
        '44v144c0 17.67 14.33 32 32 32h32c17.67 0 32-14.33 32-32V304h144c17.67 0 32-14.33 32-3'\
        "2v-32c0-17.67-14.33-32-32-32z\"\n            class=\"\"></path>\n        </svg>\n    "\
        '  </span></a></div></div>'
      )
    end
  end
end
