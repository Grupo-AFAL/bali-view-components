# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderHtmlUtilsTest < FormBuilderTestCase
  def test_translate_attribute_humanizes_when_no_translation_exists
    assert_equal "Synopsis", builder.translate_attribute(:synopsis)
  end

  def test_translate_attribute_resolves_activerecord_attributes_namespace
    with_translations(activerecord: { attributes: { movie: { synopsis: "Plot summary" } } }) do
      assert_equal "Plot summary", builder.translate_attribute(:synopsis)
    end
  end

  def test_translate_attribute_resolves_activemodel_attributes_namespace_for_form_objects
    form_class = Class.new do
      include ActiveModel::Model
      attr_accessor :name

      def self.name
        "ContactForm"
      end
    end

    with_translations(activemodel: { attributes: { contact_form: { name: "Full name" } } }) do
      form_builder = build_form_builder("contact_form", form_class.new)
      assert_equal "Full name", form_builder.translate_attribute(:name)
    end
  end

  def test_translate_attribute_falls_back_to_humanize_when_object_has_no_model_name
    plain_object = Object.new
    form_builder = build_form_builder("plain", plain_object)

    assert_equal "First name", form_builder.translate_attribute(:first_name)
  end

  private

  def build_form_builder(name, object)
    view_context = ActionController::Base.new.view_context
    Bali::FormBuilder.new(name, object, view_context, {})
  end

  def with_translations(translations)
    I18n.backend.store_translations(:en, translations)
    yield
  ensure
    I18n.backend.reload!
  end
end
