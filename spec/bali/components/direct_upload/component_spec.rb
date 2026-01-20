# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::DirectUpload::Component, type: :component do
  let(:helper) { FormHelperTest.new(nil) }
  let(:options) { {} }

  def render_component(**opts)
    helper.form_with(url: '/') do |form|
      render_inline(described_class.new(form: form, method: :attachment, **opts))
    end
  end

  describe 'default rendering' do
    it 'renders container with direct-upload controller' do
      render_component

      expect(page).to have_css '.direct-upload-component[data-controller="direct-upload"]'
    end

    it 'renders hidden file input' do
      render_component

      expect(page).to have_css 'input[type="file"].hidden', visible: :all
    end

    it 'renders drop zone by default' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="dropzone"]'
    end

    it 'renders browse button' do
      render_component

      expect(page).to have_css '.btn', text: 'Browse Files'
    end

    it 'renders file list container' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="fileList"]'
    end

    it 'renders hidden fields container' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="hiddenFields"]'
    end

    it 'renders template for file items' do
      render_component

      expect(page).to have_css 'template[data-direct-upload-target="template"]', visible: :all
    end
  end

  describe 'stimulus data values' do
    it 'sets url value to rails direct uploads path' do
      render_component

      expect(page).to have_css '[data-direct-upload-url-value]'
    end

    it 'sets multiple value to false by default' do
      render_component

      expect(page).to have_css '[data-direct-upload-multiple-value="false"]'
    end

    it 'sets max files value to 10 by default' do
      render_component

      expect(page).to have_css '[data-direct-upload-max-files-value="10"]'
    end

    it 'sets max file size value to 10 by default' do
      render_component

      expect(page).to have_css '[data-direct-upload-max-file-size-value="10"]'
    end

    it 'sets accept value to * by default' do
      render_component

      expect(page).to have_css '[data-direct-upload-accept-value="*"]'
    end

    it 'sets auto upload value to true by default' do
      render_component

      expect(page).to have_css '[data-direct-upload-auto-upload-value="true"]'
    end

    it 'sets field name value based on form object' do
      render_component

      expect(page).to have_css '[data-direct-upload-field-name-value]'
    end
  end

  describe 'multiple file mode' do
    it 'sets multiple value to true' do
      render_component(multiple: true)

      expect(page).to have_css '[data-direct-upload-multiple-value="true"]'
    end

    it 'sets multiple attribute on file input' do
      render_component(multiple: true)

      expect(page).to have_css 'input[type="file"][multiple]', visible: :all
    end

    it 'appends [] to field name' do
      render_component(multiple: true)

      expect(page).to have_css '[data-direct-upload-field-name-value*="[]"]'
    end
  end

  describe 'max files configuration' do
    it 'sets custom max files value' do
      render_component(max_files: 5)

      expect(page).to have_css '[data-direct-upload-max-files-value="5"]'
    end
  end

  describe 'max file size configuration' do
    it 'sets custom max file size value' do
      render_component(max_file_size: 20)

      expect(page).to have_css '[data-direct-upload-max-file-size-value="20"]'
    end
  end

  describe 'accept filter configuration' do
    it 'sets custom accept value' do
      render_component(accept: 'image/*,.pdf')

      expect(page).to have_css '[data-direct-upload-accept-value="image/*,.pdf"]'
    end

    it 'sets accept attribute on file input' do
      render_component(accept: 'image/*,.pdf')

      expect(page).to have_css 'input[type="file"][accept="image/*,.pdf"]', visible: :all
    end
  end

  describe 'without drop zone' do
    it 'does not render drop zone' do
      render_component(drop_zone: false)

      expect(page).not_to have_css '[data-direct-upload-target="dropzone"]'
    end

    it 'renders browse button' do
      render_component(drop_zone: false)

      expect(page).to have_css 'button.btn', text: 'Browse Files'
    end

    it 'browse button has open file picker action' do
      render_component(drop_zone: false)

      expect(page).to have_css 'button[data-action="direct-upload#openFilePicker"]'
    end
  end

  describe 'auto upload configuration' do
    it 'sets auto upload value to false' do
      render_component(auto_upload: false)

      expect(page).to have_css '[data-direct-upload-auto-upload-value="false"]'
    end
  end

  describe 'drop zone interactions' do
    it 'has drag and drop event handlers' do
      render_component

      dropzone = page.find('[data-direct-upload-target="dropzone"]')
      expect(dropzone['data-action']).to include('dragenter->direct-upload#dragenter')
      expect(dropzone['data-action']).to include('dragover->direct-upload#dragover')
      expect(dropzone['data-action']).to include('dragleave->direct-upload#dragleave')
      expect(dropzone['data-action']).to include('drop->direct-upload#drop')
    end

    it 'has click handler to open file picker' do
      render_component

      dropzone = page.find('[data-direct-upload-target="dropzone"]')
      expect(dropzone['data-action']).to include('click->direct-upload#openFilePicker')
    end
  end

  describe 'file input attributes' do
    it 'has input target' do
      render_component

      expect(page).to have_css 'input[data-direct-upload-target="input"]', visible: :all
    end

    it 'has select files action' do
      render_component

      expect(page).to have_css 'input[data-action*="direct-upload#selectFiles"]', visible: :all
    end
  end

  describe 'template structure' do
    # Template content inspection is limited in Capybara.
    # The template is verified to exist; actual content is verified via Lookbook.
    it 'template element exists' do
      render_component

      expect(page).to have_css('template[data-direct-upload-target="template"]', visible: :all)
    end
  end

  describe 'custom classes' do
    it 'allows custom classes' do
      render_component(class: 'my-custom-class')

      expect(page).to have_css '.direct-upload-component.my-custom-class'
    end
  end

  describe 'accessibility' do
    it 'renders dropzone with role="button" and tabindex' do
      render_component

      dropzone = page.find('[data-direct-upload-target="dropzone"]')
      expect(dropzone['role']).to eq('button')
      expect(dropzone['tabindex']).to eq('0')
    end

    it 'renders dropzone with aria-label' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="dropzone"][aria-label]'
    end

    it 'renders file list with role="list" and aria-label' do
      render_component

      file_list = page.find('[data-direct-upload-target="fileList"]')
      expect(file_list['role']).to eq('list')
      expect(file_list['aria-label']).to be_present
    end

    it 'renders announcer live region for screen readers' do
      render_component

      announcer = page.find('[data-direct-upload-target="announcer"]', visible: :all)
      expect(announcer['role']).to eq('status')
      expect(announcer['aria-live']).to eq('polite')
      expect(announcer.native['class']).to include('sr-only')
    end

    it 'has keyboard support handler on dropzone' do
      render_component

      dropzone = page.find('[data-direct-upload-target="dropzone"]')
      expect(dropzone['data-action']).to include('keydown->direct-upload#dropzoneKeydown')
    end
  end

  describe 'error alert' do
    it 'renders error alert container' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="errorAlert"].alert.alert-error.hidden',
                               visible: :all
    end

    it 'renders error message container' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="errorMessage"]', visible: :all
    end

    it 'renders dismiss button with action' do
      render_component

      expect(page).to have_css '[data-action="direct-upload#dismissError"]', visible: :all
    end
  end

  describe 'remove field name value' do
    it 'sets remove field name value' do
      render_component

      expect(page).to have_css '[data-direct-upload-remove-field-name-value]'
    end

    it 'remove field name includes the method name' do
      render_component

      container = page.find('.direct-upload-component')
      expect(container['data-direct-upload-remove-field-name-value']).to include('remove_attachment')
    end
  end

  describe 'remove fields container' do
    it 'renders remove fields container' do
      render_component

      expect(page).to have_css '[data-direct-upload-target="removeFields"]', visible: :all
    end
  end
end
