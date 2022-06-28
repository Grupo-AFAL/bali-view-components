# frozen_string_literal: true

require 'rails_helper'

class TestHelper < ActionView::Base; end

RSpec.describe Bali::FieldGroupWrapper::Component, type: :component do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil) }
  let(:resource) { Movie.new }
  let(:builder) { Bali::FormBuilder.new :movie, resource, helper, {} }

  let(:component) { Bali::FieldGroupWrapper::Component.new(builder, :name, @options) }

  before { @options = {} }

  subject { rendered_component }

  context 'default' do
    it 'renders' do
      render_inline(component)

      is_expected.to include(
        "<div id=\"field-name\" class=\"field \">"\
        "<label class=\"label \" for=\"movie_name\">Name</label>"\
        "</div>"
      )
    end
  end

  context 'with addons' do
    before do
      @options.merge!(
        addon_left: '<p>Left addon</p>'.html_safe,
        addon_right: '<p>Right addon</p>'.html_safe
      )
    end

    it 'renders' do
      render_inline(component)

      is_expected.to include(
        "<div id=\"field-name\" class=\"field \">"\
        "<label class=\"label \" for=\"movie_name\">Name</label>"\
        "<div class=\"field has-addons\">"\
        "<div class=\"control\"><p>Left addon</p></div><div class=\"control\">"\
        "<p>Right addon</p></div></div></div>"
      )
    end
  end
end
