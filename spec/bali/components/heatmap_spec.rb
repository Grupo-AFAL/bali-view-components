# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Heatmap::Component, type: :component do
  let(:data) do
    {
      Mon: { 0 => 5, 1 => 10, 2 => 3 },
      Tue: { 0 => 3, 1 => 0, 2 => 6 },
      Wed: { 0 => 2, 1 => 8, 2 => 4 }
    }
  end

  describe 'rendering' do
    it 'renders the heatmap structure' do
      render_inline(described_class.new(data: data))

      expect(page).to have_css('div.heatmap-component')
      expect(page).to have_css('table')
    end

    it 'renders all x-axis labels in footer' do
      render_inline(described_class.new(data: data))

      %w[Mon Tue Wed].each do |day|
        expect(page).to have_css('tfoot td', text: day)
      end
    end

    it 'renders all y-axis labels' do
      render_inline(described_class.new(data: data))

      (0..2).each do |hour|
        expect(page).to have_css('td', text: hour.to_s)
      end
    end

    it 'renders the legend with min and max values' do
      render_inline(described_class.new(data: data))

      expect(page).to have_css('.flex span', text: '0')
      expect(page).to have_css('.flex span', text: '10') # max value in data
    end

    it 'renders heatmap cells with background colors' do
      render_inline(described_class.new(data: data))

      expect(page).to have_css('.heatmap-cell[style*="background"]')
    end
  end

  describe 'slots' do
    it 'renders x_axis_title when provided' do
      render_inline(described_class.new(data: data)) do |c|
        c.with_x_axis_title('Days')
      end

      expect(page).to have_css('tfoot td', text: 'Days')
    end

    it 'renders y_axis_title when provided' do
      render_inline(described_class.new(data: data)) do |c|
        c.with_y_axis_title('Hours')
      end

      expect(page).to have_css('th', text: 'Hours')
    end

    it 'renders legend_title when provided' do
      render_inline(described_class.new(data: data)) do |c|
        c.with_legend_title('Activity')
      end

      expect(page).to have_css('.flex span.font-bold', text: 'Activity')
    end

    it 'renders hovercard_title when provided' do
      result = render_inline(described_class.new(data: data)) do |c|
        c.with_hovercard_title('Details')
      end

      # HoverCard content is inside a <template> tag, so we check the raw HTML
      expect(result.to_html).to include('Details')
    end

    it 'does not render x_axis_title row when not provided' do
      render_inline(described_class.new(data: data))

      expect(page).not_to have_css('tfoot tr td[colspan]')
    end
  end

  describe 'dimensions' do
    it 'accepts custom width and height' do
      component = described_class.new(data: data, width: 600, height: 300)

      expect(component.send(:cell_width)).to eq(150) # 600 / (3 + 1)
      expect(component.send(:cell_height)).to eq(100) # 300 / 3
    end

    it 'clamps width to minimum 100' do
      component = described_class.new(data: data, width: 50)

      expect(component.send(:cell_width)).to eq(25) # 100 / (3 + 1)
    end

    it 'clamps width to maximum 2000' do
      component = described_class.new(data: data, width: 3000)

      expect(component.send(:cell_width)).to eq(500) # 2000 / (3 + 1)
    end
  end

  describe 'color customization' do
    it 'accepts custom base color' do
      render_inline(described_class.new(data: data, color: '#FF0000'))

      # Gradient colors should be generated from the base color
      expect(page).to have_css('.heatmap-cell[style*="background"]')
    end
  end

  describe 'edge cases' do
    it 'handles empty data gracefully' do
      render_inline(described_class.new(data: {}))

      expect(page).to have_css('div.heatmap-component')
      expect(page).to have_css('table')
    end

    it 'handles data with all zero values' do
      zero_data = { A: { 0 => 0, 1 => 0 }, B: { 0 => 0, 1 => 0 } }

      render_inline(described_class.new(data: zero_data))

      expect(page).to have_css('div.heatmap-component')
      expect(page).to have_css('.flex span', text: '0')
    end

    it 'handles missing values in nested data' do
      sparse_data = { A: { 0 => 5 }, B: { 1 => 10 } }
      component = described_class.new(data: sparse_data)

      # Should return 0 for missing values
      expect(component.value_at(:A, 1)).to eq(0)
      expect(component.value_at(:B, 0)).to eq(0)
    end
  end

  describe 'public API' do
    it 'exposes x_labels' do
      component = described_class.new(data: data)

      expect(component.x_labels).to eq(%i[Mon Tue Wed])
    end

    it 'exposes y_labels as a range' do
      component = described_class.new(data: data)

      expect(component.y_labels).to eq(0..2)
    end

    it 'exposes max_value' do
      component = described_class.new(data: data)

      expect(component.max_value).to eq(10)
    end

    it 'exposes gradient_colors' do
      component = described_class.new(data: data)

      expect(component.gradient_colors).to be_an(Array)
      expect(component.gradient_colors).not_to be_empty
    end

    it 'provides value_at helper' do
      component = described_class.new(data: data)

      expect(component.value_at(:Mon, 1)).to eq(10)
      expect(component.value_at(:Tue, 2)).to eq(6)
    end

    it 'provides cell_style helper' do
      component = described_class.new(data: data, width: 480, height: 480)
      style = component.cell_style(5)

      expect(style).to have_key(:width)
      expect(style).to have_key(:height)
      expect(style).to have_key(:background)
    end

    it 'provides legend_segment_style helper' do
      component = described_class.new(data: data, width: 480)
      style = component.legend_segment_style('#FF0000')

      expect(style).to eq(background: '#FF0000', width: "#{480 / component.gradient_colors.size}px")
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(data: data, class: 'custom-class'))

      expect(page).to have_css('div.heatmap-component.custom-class')
    end

    it 'accepts id attribute' do
      render_inline(described_class.new(data: data, id: 'my-heatmap'))

      expect(page).to have_css('#my-heatmap')
    end
  end
end
