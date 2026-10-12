# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderDirectUploadFieldsTest < FormBuilderTestCase
  def test_a_field_that_does_not_ask_for_auto_upload_warns_nothing
    assert_not_deprecated(Bali.deprecator) { builder.direct_upload_field(:poster) }
  end

  def test_auto_upload_still_reaches_the_component_that_warns_about_it
    assert_deprecated(/DirectUpload\(auto_upload:\) is deprecated/, Bali.deprecator) do
      builder.direct_upload_field(:poster, auto_upload: true)
    end
  end
end
