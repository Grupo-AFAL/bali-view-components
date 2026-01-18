# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Timeline::Component, type: :component do
  describe 'base rendering' do
    it 'renders a timeline with DaisyUI classes' do
      render_inline(described_class.new)

      expect(page).to have_css('ul.timeline.timeline-vertical')
    end

    it 'accepts custom classes via options' do
      render_inline(described_class.new(class: 'my-custom-class'))

      expect(page).to have_css('ul.timeline.my-custom-class')
    end

    it 'accepts additional HTML attributes' do
      render_inline(described_class.new(data: { testid: 'my-timeline' }))

      expect(page).to have_css('ul.timeline[data-testid="my-timeline"]')
    end
  end

  describe 'position variants' do
    it 'renders left position by default' do
      render_inline(described_class.new)

      expect(page).to have_css('ul.timeline.timeline-vertical')
      expect(page).not_to have_css('ul.timeline-snap-icon')
    end

    it 'renders center position with timeline-centered class' do
      render_inline(described_class.new(position: :center))

      expect(page).to have_css('ul.timeline.timeline-centered')
    end

    it 'renders right position with snap-icon modifier' do
      render_inline(described_class.new(position: :right))

      expect(page).to have_css('ul.timeline.timeline-snap-icon')
    end

    it 'accepts position as string' do
      render_inline(described_class.new(position: 'center'))

      expect(page).to have_css('ul.timeline.timeline-centered')
    end
  end

  describe 'timeline items' do
    it 'renders items with DaisyUI structure' do
      render_inline(described_class.new) do |c|
        c.with_tag_item(heading: 'January 2022') { 'Content' }
      end

      expect(page).to have_css('li', count: 1)
      expect(page).to have_css('.timeline-middle')
      # Both timeline-start and timeline-end are rendered, CSS controls visibility
      expect(page).to have_css('.timeline-start.timeline-box.timeline-content-box')
      expect(page).to have_css('.timeline-end.timeline-box.timeline-content-box')
    end

    it 'renders item heading in both content boxes' do
      render_inline(described_class.new) do |c|
        c.with_tag_item(heading: 'January 2022') { 'Content' }
      end

      # Heading appears in both content boxes (CSS hides one based on position)
      expect(page).to have_css('.timeline-start p.font-semibold', text: 'January 2022')
      expect(page).to have_css('.timeline-end p.font-semibold', text: 'January 2022')
    end

    it 'renders item content in both content boxes' do
      render_inline(described_class.new) do |c|
        c.with_tag_item { 'My timeline content' }
      end

      # Content appears in both boxes (CSS hides one based on position)
      expect(page).to have_css('.timeline-start', text: 'My timeline content')
      expect(page).to have_css('.timeline-end', text: 'My timeline content')
    end

    it 'renders items with icons' do
      render_inline(described_class.new) do |c|
        c.with_tag_item(icon: 'check')
      end

      expect(page).to have_css('.timeline-middle .icon-component')
    end

    it 'renders default circle icon when no icon specified' do
      render_inline(described_class.new) do |c|
        c.with_tag_item
      end

      expect(page).to have_css('.timeline-middle .icon-component')
    end

    it 'renders items with color variants' do
      render_inline(described_class.new) do |c|
        c.with_tag_item(color: :success)
      end

      expect(page).to have_css('.timeline-middle.text-success')
    end

    it 'renders colored connecting lines' do
      render_inline(described_class.new) do |c|
        c.with_tag_item(color: :primary)
      end

      expect(page).to have_css('hr.bg-primary', count: 2)
    end
  end

  describe 'timeline headers' do
    it 'renders headers with DaisyUI badge' do
      render_inline(described_class.new) do |c|
        c.with_tag_header(text: 'Start')
      end

      expect(page).to have_css('li', count: 1)
      expect(page).to have_css('.timeline-middle')
      expect(page).to have_css('.badge', text: 'Start')
    end

    it 'renders headers with default neutral color' do
      render_inline(described_class.new) do |c|
        c.with_tag_header(text: 'Start')
      end

      expect(page).to have_css('.badge.badge-neutral', text: 'Start')
    end

    it 'renders headers with color variant' do
      render_inline(described_class.new) do |c|
        c.with_tag_header(text: 'Important', color: :primary)
      end

      expect(page).to have_css('.badge.badge-primary', text: 'Important')
    end

    it 'supports legacy tag_class for backwards compatibility' do
      render_inline(described_class.new) do |c|
        c.with_tag_header(text: 'Legacy', tag_class: 'badge-outline badge-secondary')
      end

      expect(page).to have_css('.badge.badge-outline.badge-secondary', text: 'Legacy')
    end
  end

  describe 'multiple items' do
    it 'renders multiple items and headers' do
      render_inline(described_class.new) do |c|
        c.with_tag_header(text: 'Start')
        c.with_tag_item(heading: 'Event 1') { 'Content 1' }
        c.with_tag_item(heading: 'Event 2') { 'Content 2' }
        c.with_tag_header(text: 'End')
      end

      expect(page).to have_css('li', count: 4)
      expect(page).to have_css('.badge', count: 2)
      expect(page).to have_css('.timeline-end.timeline-box', count: 2)
    end
  end

  describe 'constants' do
    it 'defines BASE_CLASSES' do
      expect(described_class::BASE_CLASSES).to eq('timeline timeline-vertical')
    end

    it 'defines frozen POSITIONS hash' do
      expect(described_class::POSITIONS).to be_frozen
      expect(described_class::POSITIONS.keys).to contain_exactly(:left, :center, :right)
    end
  end
end

RSpec.describe Bali::Timeline::Item::Component, type: :component do
  describe 'constants' do
    it 'defines frozen COLORS hash' do
      expect(described_class::COLORS).to be_frozen
      expect(described_class::COLORS.keys).to include(:default, :primary, :success, :error)
    end

    it 'defines frozen LINE_COLORS hash' do
      expect(described_class::LINE_COLORS).to be_frozen
      expect(described_class::LINE_COLORS[:primary]).to eq('bg-primary')
    end

    it 'defines MARKER_BASE_CLASSES' do
      expect(described_class::MARKER_BASE_CLASSES).to eq('timeline-middle')
    end
  end
end

RSpec.describe Bali::Timeline::Header::Component, type: :component do
  describe 'constants' do
    it 'defines frozen COLORS hash' do
      expect(described_class::COLORS).to be_frozen
      expect(described_class::COLORS.keys).to include(:default, :primary, :success, :error, :ghost, :outline)
    end

    it 'defaults to badge-neutral' do
      expect(described_class::COLORS[:default]).to eq('badge-neutral')
    end
  end
end
