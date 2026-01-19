# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::StatCard::Component, type: :component do
  let(:default_attrs) do
    {
      title: 'Total Users',
      value: '1,234',
      icon_name: 'users',
      color: :primary
    }
  end

  describe 'basic rendering' do
    it 'renders a card with the title' do
      render_inline(described_class.new(**default_attrs))

      expect(page).to have_text('Total Users')
    end

    it 'renders the value' do
      render_inline(described_class.new(**default_attrs))

      expect(page).to have_text('1,234')
    end

    it 'renders the icon' do
      render_inline(described_class.new(**default_attrs))

      expect(page).to have_css('svg') # Lucide icon
    end

    it 'renders inside a Card component' do
      render_inline(described_class.new(**default_attrs))

      expect(page).to have_css('.card')
    end
  end

  describe 'colors' do
    described_class::COLORS.each_key do |color|
      it "applies #{color} color classes" do
        render_inline(described_class.new(**default_attrs.merge(color: color)))

        color_classes = described_class::COLORS[color]
        expect(page).to have_css(".#{color_classes[:bg].gsub('/', '\\/')}")
      end
    end

    it 'defaults to primary color' do
      render_inline(described_class.new(**default_attrs.except(:color).merge(color: nil)))

      # Should fallback to primary
      expect(page).to have_css('.bg-primary\\/10')
    end
  end

  describe 'footer slot' do
    it 'renders the footer when provided' do
      render_inline(described_class.new(**default_attrs)) do |card|
        card.with_footer { 'Footer content' }
      end

      expect(page).to have_text('Footer content')
    end

    it 'does not render footer container when not provided' do
      render_inline(described_class.new(**default_attrs))

      # Footer container should not exist without the slot
      expect(page).to have_css('.card')
      expect(page).not_to have_css('.mt-3.flex.items-center.gap-1.text-sm')
    end
  end

  describe 'private attribute readers' do
    it 'has private title reader' do
      component = described_class.new(**default_attrs)
      expect(component.private_methods).to include(:title)
    end

    it 'has private value reader' do
      component = described_class.new(**default_attrs)
      expect(component.private_methods).to include(:value)
    end

    it 'has private icon_name reader' do
      component = described_class.new(**default_attrs)
      expect(component.private_methods).to include(:icon_name)
    end

    it 'has private color reader' do
      component = described_class.new(**default_attrs)
      expect(component.private_methods).to include(:color)
    end

    it 'has private options reader' do
      component = described_class.new(**default_attrs)
      expect(component.private_methods).to include(:options)
    end
  end

  describe 'icon background classes' do
    it 'returns correct bg class for primary' do
      component = described_class.new(**default_attrs.merge(color: :primary))
      expect(component.icon_bg_class).to eq('bg-primary/10')
    end

    it 'returns correct bg class for warning' do
      component = described_class.new(**default_attrs.merge(color: :warning))
      expect(component.icon_bg_class).to eq('bg-warning/10')
    end

    it 'falls back to primary for unknown color' do
      component = described_class.new(**default_attrs.merge(color: :unknown))
      expect(component.icon_bg_class).to eq('bg-primary/10')
    end
  end

  describe 'icon text classes' do
    it 'returns correct text class for primary' do
      component = described_class.new(**default_attrs.merge(color: :primary))
      expect(component.icon_text_class).to eq('text-primary')
    end

    it 'returns correct text class for success' do
      component = described_class.new(**default_attrs.merge(color: :success))
      expect(component.icon_text_class).to eq('text-success')
    end

    it 'falls back to primary for unknown color' do
      component = described_class.new(**default_attrs.merge(color: :unknown))
      expect(component.icon_text_class).to eq('text-primary')
    end
  end

  describe 'COLORS constant' do
    it 'is frozen' do
      expect(described_class::COLORS).to be_frozen
    end

    it 'has bg and text keys for each color' do
      described_class::COLORS.each_value do |classes|
        expect(classes).to have_key(:bg)
        expect(classes).to have_key(:text)
      end
    end
  end

  describe 'card_options' do
    it 'includes bordered style' do
      component = described_class.new(**default_attrs)
      expect(component.card_options).to include(style: :bordered)
    end

    it 'passes through custom options' do
      component = described_class.new(**default_attrs.merge(class: 'custom-class'))
      expect(component.card_options).to include(class: 'custom-class')
    end

    it 'passes through data attributes' do
      component = described_class.new(**default_attrs.merge(data: { testid: 'stat' }))
      expect(component.card_options).to include(data: { testid: 'stat' })
    end
  end

  describe 'icon_container_classes' do
    it 'includes base classes' do
      component = described_class.new(**default_attrs)
      expect(component.icon_container_classes).to include('p-3')
      expect(component.icon_container_classes).to include('rounded-full')
    end

    it 'includes color-specific background class' do
      component = described_class.new(**default_attrs.merge(color: :warning))
      expect(component.icon_container_classes).to include('bg-warning/10')
    end
  end

  describe 'numeric values' do
    it 'handles integer values' do
      render_inline(described_class.new(**default_attrs.merge(value: 42)))

      expect(page).to have_text('42')
    end

    it 'handles formatted currency values' do
      render_inline(described_class.new(**default_attrs.merge(value: '$1,234,567')))

      expect(page).to have_text('$1,234,567')
    end

    it 'handles percentage values' do
      render_inline(described_class.new(**default_attrs.merge(value: '78%')))

      expect(page).to have_text('78%')
    end
  end
end
