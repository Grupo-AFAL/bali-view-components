# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::HoverCard::Component, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }

  describe 'constants' do
    it 'has frozen PLACEMENTS constant' do
      expect(described_class::PLACEMENTS).to be_frozen
      expect(described_class::PLACEMENTS).to include('auto', 'top', 'bottom', 'left', 'right')
    end

    it 'has frozen TRIGGERS constant' do
      expect(described_class::TRIGGERS).to be_frozen
      expect(described_class::TRIGGERS[:hover]).to eq('mouseenter focus')
      expect(described_class::TRIGGERS[:click]).to eq('click')
    end

    it 'has DEFAULT_Z_INDEX constant' do
      expect(described_class::DEFAULT_Z_INDEX).to eq(9999)
    end
  end

  describe 'rendering' do
    context 'with template content' do
      it 'renders wrapper with hover-card-component class' do
        render_inline(component) do
          '<p>Content</p>'.html_safe
        end

        expect(page).to have_css('div.hover-card-component')
      end

      it 'includes template target for content' do
        render_inline(component) do
          '<p>Content</p>'.html_safe
        end

        expect(rendered_content).to include('data-hovercard-target="template"')
        expect(rendered_content).to include('Content')
      end

      it 'wraps content with hover-card-content class by default' do
        render_inline(component) do
          '<p>Content</p>'.html_safe
        end

        # Content is inside a <template> element, check rendered_content
        expect(rendered_content).to include('class="hover-card-content"')
      end
    end

    context 'with trigger slot' do
      it 'renders trigger with data attribute' do
        render_inline(component) do |c|
          c.with_trigger { 'Trigger text' }
        end

        expect(page).to have_css('[data-hovercard-target="trigger"]', text: 'Trigger text')
      end
    end
  end

  describe 'hover_url parameter' do
    let(:options) { { hover_url: '/content-endpoint' } }

    it 'sets url value for async loading' do
      render_inline(component)

      expect(rendered_content).to include('data-hovercard-url-value="/content-endpoint"')
    end

    it 'does not render template when using hover_url' do
      render_inline(component)

      expect(rendered_content).not_to include('data-hovercard-target="template"')
    end
  end

  describe 'placement parameter' do
    context 'with valid placement' do
      let(:options) { { placement: 'top-start' } }

      it 'applies placement value' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-placement-value="top-start"')
      end
    end

    context 'with invalid placement' do
      let(:options) { { placement: 'invalid' } }

      it 'falls back to auto' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-placement-value="auto"')
      end
    end

    described_class::PLACEMENTS.each do |placement|
      it "accepts #{placement} placement" do
        render_inline(described_class.new(placement: placement))

        expect(rendered_content).to include("data-hovercard-placement-value=\"#{placement}\"")
      end
    end
  end

  describe 'open_on_click parameter' do
    context 'when false (default)' do
      it 'uses hover trigger' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-trigger-value="mouseenter focus"')
      end
    end

    context 'when true' do
      let(:options) { { open_on_click: true } }

      it 'uses click trigger' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-trigger-value="click"')
      end
    end
  end

  describe 'content_padding parameter' do
    context 'when true (default)' do
      it 'wraps content with padding class' do
        render_inline(component) do
          '<p>Content</p>'.html_safe
        end

        # Content is inside a <template> element, check rendered_content
        expect(rendered_content).to include('class="hover-card-content"')
      end

      it 'sets content_padding_value to true' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-content-padding-value="true"')
      end
    end

    context 'when false' do
      let(:options) { { content_padding: false } }

      it 'does not wrap content with padding class' do
        render_inline(component) do
          '<p>Content</p>'.html_safe
        end

        expect(page).not_to have_css('.hover-card-content')
      end

      it 'sets content_padding_value to false' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-content-padding-value="false"')
      end
    end
  end

  describe 'arrow parameter' do
    context 'when true (default)' do
      it 'sets arrow_value to true' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-arrow-value="true"')
      end
    end

    context 'when false' do
      let(:options) { { arrow: false } }

      it 'sets arrow_value to false' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-arrow-value="false"')
      end
    end
  end

  describe 'z_index parameter' do
    context 'with default value' do
      it 'uses DEFAULT_Z_INDEX' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-z-index-value="9999"')
      end
    end

    context 'with custom value' do
      let(:options) { { z_index: 10_001 } }

      it 'applies custom z_index' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-z-index-value="10001"')
      end
    end
  end

  describe 'append_to parameter' do
    context 'with default value' do
      it 'appends to body' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-append-to-value="body"')
      end
    end

    context 'with parent' do
      let(:options) { { append_to: 'parent' } }

      it 'appends to parent' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-append-to-value="parent"')
      end
    end

    context 'with CSS selector' do
      let(:options) { { append_to: '#my-container' } }

      it 'appends to selector' do
        render_inline(component)

        expect(rendered_content).to include('data-hovercard-append-to-value="#my-container"')
      end
    end
  end

  describe 'options passthrough' do
    let(:options) { { class: 'custom-class', id: 'my-hovercard' } }

    it 'merges custom classes' do
      render_inline(component)

      expect(page).to have_css('div.hover-card-component.custom-class')
    end

    it 'passes through other HTML attributes' do
      render_inline(component)

      expect(page).to have_css('div#my-hovercard')
    end

    context 'with custom data attributes' do
      let(:options) { { data: { testid: 'my-test', custom: 'value' } } }

      it 'merges custom data attributes with stimulus data' do
        render_inline(component)

        expect(rendered_content).to include('data-testid="my-test"')
        expect(rendered_content).to include('data-custom="value"')
        expect(rendered_content).to include('data-controller="hovercard"')
      end
    end
  end

  describe 'stimulus controller' do
    it 'has hovercard controller' do
      render_inline(component)

      expect(rendered_content).to include('data-controller="hovercard"')
    end
  end
end
