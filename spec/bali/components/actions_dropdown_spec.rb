# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ActionsDropdown::Component, type: :component do
  describe 'basic rendering' do
    it 'renders dropdown component with DaisyUI classes' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-start'
    end

    it 'renders with DaisyUI btn classes on trigger' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '.btn.btn-ghost.btn-sm.btn-circle'
    end

    it 'renders dropdown-content menu' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'ul.dropdown-content.menu'
      expect(page).to have_css 'ul.dropdown-content li a', text: 'Edit'
    end

    it 'renders items inside li elements' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#edit')
        c.with_item(name: 'Delete', href: '#delete', method: :delete)
      end

      expect(page).to have_css 'ul.menu li', count: 2
    end

    it 'applies custom classes via options' do
      render_inline(described_class.new(class: 'my-custom-class')) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.my-custom-class'
    end

    it 'renders default ellipsis-h icon' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'button[type="button"] svg'
    end
  end

  describe 'custom icon' do
    it 'allows changing the trigger icon' do
      render_inline(described_class.new(icon: 'more')) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'button[type="button"] svg'
    end
  end

  describe 'custom trigger' do
    it 'renders custom trigger when provided' do
      render_inline(described_class.new) do |c|
        c.with_trigger do
          '<button class="custom-trigger">Actions</button>'.html_safe
        end
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'button.custom-trigger', text: 'Actions'
      expect(page).not_to have_css 'button.btn-circle'
    end
  end

  describe 'accessibility' do
    it 'uses semantic button element for trigger' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'button[type="button"][aria-haspopup="true"]'
    end
  end

  describe 'custom content fallback' do
    it 'renders block content when no items provided' do
      render_inline(described_class.new) do
        '<li><a href="#">Custom Link</a></li>'.html_safe
      end

      expect(page).to have_css 'ul.menu li a', text: 'Custom Link'
    end
  end

  describe 'render? behavior' do
    it 'does not render when no items and no content' do
      result = render_inline(described_class.new)

      expect(result.to_html).to be_empty
    end

    it 'renders when content is provided without items' do
      render_inline(described_class.new) do
        '<li>Content</li>'.html_safe
      end

      expect(page).to have_css 'div.dropdown'
    end
  end

  describe 'horizontal alignment' do
    it 'supports align start (default)' do
      render_inline(described_class.new(align: :start)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-start'
    end

    it 'supports align center' do
      render_inline(described_class.new(align: :center)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-center'
    end

    it 'supports align end' do
      render_inline(described_class.new(align: :end)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-end'
    end
  end

  describe 'vertical direction' do
    it 'supports direction top' do
      render_inline(described_class.new(direction: :top)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-top'
    end

    it 'supports direction bottom' do
      render_inline(described_class.new(direction: :bottom)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-bottom'
    end

    it 'supports direction left' do
      render_inline(described_class.new(direction: :left)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-left'
    end

    it 'supports direction right' do
      render_inline(described_class.new(direction: :right)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-right'
    end
  end

  describe 'combined positions' do
    it 'supports direction and alignment together' do
      render_inline(described_class.new(direction: :top, align: :end)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-top.dropdown-end'
    end
  end

  describe 'menu width' do
    it 'uses medium width by default' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'ul.dropdown-content.w-52'
    end

    it 'supports small width' do
      render_inline(described_class.new(width: :sm)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'ul.dropdown-content.w-40'
    end

    it 'supports large width' do
      render_inline(described_class.new(width: :lg)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'ul.dropdown-content.w-64'
    end

    it 'supports extra large width' do
      render_inline(described_class.new(width: :xl)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'ul.dropdown-content.w-80'
    end
  end

  describe 'popover mode' do
    it 'renders HoverCard component when popover: true' do
      render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '.hover-card-component[data-controller="hovercard"]'
    end

    it 'uses click trigger in popover mode' do
      render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '[data-hovercard-trigger-value="click"]'
    end

    it 'appends to body in popover mode' do
      render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '[data-hovercard-append-to-value="body"]'
    end

    it 'does not show arrow in popover mode' do
      render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '[data-hovercard-arrow-value="false"]'
    end

    it 'renders menu inside template for Tippy' do
      result = render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(result.to_html).to include('data-hovercard-target="template"')
      expect(result.to_html).to include('ul')
      expect(result.to_html).to include('menu')
    end

    it 'renders items correctly in popover mode' do
      result = render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#edit')
        c.with_item(name: 'Delete', href: '#delete', method: :delete)
      end

      expect(result.to_html.scan('<li>').count).to eq 2
    end

    it 'does not render CSS dropdown wrapper in popover mode' do
      render_inline(described_class.new(popover: true)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).not_to have_css 'div.dropdown'
    end

    it 'maps direction and align to tippy placement' do
      component = described_class.new(popover: true, direction: :top, align: :end)
      expect(component.tippy_placement).to eq 'top-end'
    end

    it 'defaults placement to bottom-start' do
      component = described_class.new(popover: true)
      expect(component.tippy_placement).to eq 'bottom-start'
    end

    it 'supports custom trigger in popover mode' do
      render_inline(described_class.new(popover: true)) do |c|
        c.with_trigger do
          '<button class="custom-trigger">Actions</button>'.html_safe
        end
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '[data-hovercard-target="trigger"] button.custom-trigger', text: 'Actions'
    end
  end
end
