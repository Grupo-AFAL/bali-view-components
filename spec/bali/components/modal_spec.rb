# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Modal::Component, type: :component do
  describe 'basic rendering' do
    it 'renders with modal-open when active is true' do
      render_inline(described_class.new(active: true))

      expect(page).to have_css 'div.modal.modal-open'
    end

    it 'renders without modal-open when active is false' do
      render_inline(described_class.new(active: false))

      expect(page).to have_css 'div.modal'
      expect(page).not_to have_css 'div.modal-open'
    end

    it 'renders with modal-box' do
      render_inline(described_class.new)

      expect(page).to have_css 'div.modal-box'
    end

    it 'renders close button' do
      render_inline(described_class.new)

      expect(page).to have_css 'button[aria-label="Close modal"]'
    end

    it 'generates unique modal id' do
      render_inline(described_class.new)

      expect(page).to have_css 'div.modal[id^="modal-"]'
    end

    it 'uses custom modal id when provided' do
      render_inline(described_class.new(id: 'custom-modal'))

      expect(page).to have_css 'div.modal#custom-modal'
    end
  end

  describe 'accessibility' do
    it 'has role dialog' do
      render_inline(described_class.new)

      expect(page).to have_css 'div.modal[role="dialog"]'
    end

    it 'has aria-modal attribute' do
      render_inline(described_class.new)

      expect(page).to have_css 'div.modal[aria-modal="true"]'
    end

    it 'has aria-labelledby pointing to title' do
      render_inline(described_class.new(id: 'test-modal'))

      expect(page).to have_css 'div.modal[aria-labelledby="test-modal-title"]'
    end

    it 'has aria-describedby when body slot is used' do
      render_inline(described_class.new(id: 'test-modal')) do |modal|
        modal.with_header(title: 'Test')
        modal.with_body { 'Body content' }
      end

      expect(page).to have_css 'div.modal[aria-describedby="test-modal-description"]'
      expect(page).to have_css '#test-modal-description', text: 'Body content'
    end

    it 'does not have aria-describedby when body slot is not used' do
      render_inline(described_class.new) do
        'Just content'
      end

      expect(page).not_to have_css 'div.modal[aria-describedby]'
    end
  end

  describe 'content' do
    it 'renders custom content' do
      render_inline(described_class.new) do
        '<p>Hello World!</p>'.html_safe
      end

      expect(page).to have_css 'p', text: 'Hello World!'
    end
  end

  describe 'sizes' do
    %i[sm md lg xl full].each do |size|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size))

        expect(page).to have_css "div.modal-box.max-w-#{size}"
      end
    end
  end

  describe 'custom classes' do
    it 'merges custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css 'div.modal-component.custom-class'
    end
  end

  describe 'header slot' do
    it 'renders header with title' do
      render_inline(described_class.new(id: 'test-modal')) do |modal|
        modal.with_header(title: 'My Title')
      end

      expect(page).to have_css 'h3#test-modal-title', text: 'My Title'
    end

    it 'renders header with badge' do
      render_inline(described_class.new) do |modal|
        modal.with_header(title: 'Title', badge: 'New', badge_color: :info)
      end

      expect(page).to have_css 'h3', text: 'Title'
      expect(page).to have_css '.badge', text: 'New'
    end

    it 'positions badge correctly in header' do
      render_inline(described_class.new) do |modal|
        modal.with_header(title: 'Title', badge: 'Badge')
      end

      # Header should have flex layout with justify-between for proper badge positioning
      expect(page).to have_css '.flex.items-center.justify-between'
    end

    it 'includes close button in header by default' do
      render_inline(described_class.new) do |modal|
        modal.with_header(title: 'Title')
      end

      expect(page).to have_css 'button[aria-label="Close modal"]'
    end

    it 'can hide close button in header' do
      render_inline(described_class.new) do |modal|
        modal.with_header(title: 'Title', close_button: false)
      end

      # Should not have close button when header has close_button: false
      # Note: the standalone close button is also hidden when header is present
      expect(page).not_to have_css 'button[aria-label="Close modal"]'
    end

    it 'hides standalone close button when header is present' do
      render_inline(described_class.new) do |modal|
        modal.with_header(title: 'Title')
      end

      # Should only have one close button (in header), not the absolute positioned one
      expect(page).to have_css('button[aria-label="Close modal"]', count: 1)
      expect(page).not_to have_css 'button.absolute'
    end
  end

  describe 'body slot' do
    it 'renders body content' do
      render_inline(described_class.new) do |modal|
        modal.with_body { 'Body content here' }
      end

      expect(page).to have_css '.modal-body', text: 'Body content here'
    end

    it 'has description id for accessibility' do
      render_inline(described_class.new(id: 'test-modal')) do |modal|
        modal.with_body { 'Description text' }
      end

      expect(page).to have_css '#test-modal-description', text: 'Description text'
    end
  end

  describe 'actions slot' do
    it 'renders actions' do
      render_inline(described_class.new) do |modal|
        modal.with_actions do
          '<button class="btn">Save</button>'.html_safe
        end
      end

      expect(page).to have_css '.modal-action button.btn', text: 'Save'
    end

    it 'has proper styling for actions' do
      render_inline(described_class.new) do |modal|
        modal.with_actions do
          '<button>Action</button>'.html_safe
        end
      end

      expect(page).to have_css '.modal-action.flex.justify-end'
    end
  end

  describe 'combined slots' do
    it 'renders all slots together' do
      render_inline(described_class.new(id: 'full-modal')) do |modal|
        modal.with_header(title: 'Full Modal', badge: 'Important')
        modal.with_body { 'Modal body content' }
        modal.with_actions { '<button class="btn">Done</button>'.html_safe }
      end

      expect(page).to have_css '#full-modal'
      expect(page).to have_css 'h3', text: 'Full Modal'
      expect(page).to have_css '.badge', text: 'Important'
      expect(page).to have_css '.modal-body', text: 'Modal body content'
      expect(page).to have_css '.modal-action button.btn', text: 'Done'
    end
  end
end
