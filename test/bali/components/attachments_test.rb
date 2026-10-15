# frozen_string_literal: true

require "test_helper"

class BaliAttachmentsComponentTest < ComponentTestCase
  PNG = Rails.root.join("app/assets/images/avatar.png")

  def setup
    @workout = Workout.create!
  end

  # A form that fails validation hands the view its record with the new upload still
  # unsaved, and asking that attachment for its URL raises "Cannot get a signed_id for a
  # new record": the form meant to come back as a 422 becomes an error page.
  def test_an_unsaved_attachment_is_left_out
    pdf = attach("minutes.pdf", "application/pdf")

    render_inline(Bali::Attachments::Component.new(attachments: [ pdf, unsaved("pending.pdf") ]))

    assert_selector("li", text: "minutes.pdf")
    assert_no_text("pending.pdf")
  end

  def test_with_empty_text_false_nothing_renders_without_a_saved_attachment
    render_inline(Bali::Attachments::Component.new(attachments: [ unsaved("pending.pdf") ], empty_text: false))

    assert_no_selector(".attachments-component")
  end

  def test_an_empty_list_says_so_with_the_text_from_the_locale_files
    render_inline(Bali::Attachments::Component.new(attachments: @workout.files))

    assert_selector("ul.attachments-component > li.attachments-empty", text: "No attachments", visible: :all)
  end

  # The id is what the host's `turbo_stream.remove attachment` targets.
  def test_each_item_carries_the_dom_id_of_its_attachment
    pdf = attach("minutes.pdf", "application/pdf")

    render_inline(Bali::Attachments::Component.new(attachments: @workout.files))

    assert_selector("ul.attachments-component > li#attachment_#{pdf.id}")
  end

  def test_an_image_renders_as_a_thumbnail_of_a_variant_linking_to_the_file
    attach("defect.png", "image/png", io: StringIO.new(PNG.binread))

    render_inline(Bali::Attachments::Component.new(attachments: @workout.files))

    assert_selector("a[href*='/rails/active_storage/blobs/'][target='_blank'] " \
                    "img[src*='/rails/active_storage/representations/'][alt='defect.png']")
  end

  # An SVG is not variable, and Active Storage serves it as `application/octet-stream`,
  # which an `<img>` does not draw.
  def test_a_file_that_cannot_be_resized_renders_as_a_chip_that_downloads_it
    attach("diagram.svg", "image/svg+xml", io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'/>"))

    render_inline(Bali::Attachments::Component.new(attachments: @workout.files))

    assert_no_selector("img")
    assert_selector("a.btn[href*='disposition=attachment'][title='Download diagram.svg'] " \
                    "span.truncate", text: "diagram.svg")
  end

  def test_the_chip_is_capped_so_a_long_name_truncates
    attach("#{'very long name ' * 10}.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")

    render_inline(Bali::Attachments::Component.new(attachments: @workout.files))

    assert_selector("a.btn.max-w-\\[16rem\\] span.truncate")
  end

  def test_remove_path_renders_a_delete_button_with_the_filename_in_its_name_and_confirm
    pdf = attach("minutes.pdf", "application/pdf")

    fragment = render_inline(Bali::Attachments::Component.new(
                               attachments: @workout.files,
                               remove_path: ->(attachment) { "/attachments/#{attachment.id}" }
                             ))

    assert_selector("li##{dom_id_for(pdf)} button[title='Remove minutes.pdf']", text: "Remove minutes.pdf")
    assert fragment.at_css("li##{dom_id_for(pdf)} button template form[action='/attachments/#{pdf.id}']" \
                           "[data-turbo-confirm='Remove \"minutes.pdf\"?'] input[name='_method'][value='delete']")
  end

  # Hosts render the list inside the record's form, where a `button_to` form would be nested
  # (#1473): the parser drops its start tag, and its `</form>` closes the record's form early.
  def test_the_remove_buttons_have_no_form_around_them_so_the_list_can_sit_inside_a_form
    attach("minutes.pdf", "application/pdf")

    render_inline(Bali::Attachments::Component.new(
                    attachments: @workout.files, remove_path: ->(attachment) { "/attachments/#{attachment.id}" }
                  ))

    assert_no_selector("form button", visible: :all)
    assert_selector("li button[form][data-controller='delete-link']")
  end

  # Who may delete is the host's policy: the lambda answers per attachment, and nil is "not this one".
  def test_a_nil_remove_path_leaves_that_attachment_without_a_delete_button
    kept = attach("signed.pdf", "application/pdf")
    removable = attach("draft.pdf", "application/pdf")

    render_inline(Bali::Attachments::Component.new(
                    attachments: @workout.files,
                    remove_path: ->(attachment) { "/attachments/#{attachment.id}" if attachment == removable }
                  ))

    assert_no_selector("li##{dom_id_for(kept)} button")
    assert_selector("li##{dom_id_for(removable)} button")
  end

  def test_without_remove_path_there_is_no_delete_button
    attach("minutes.pdf", "application/pdf")

    render_inline(Bali::Attachments::Component.new(attachments: @workout.files))

    assert_no_selector("button")
  end

  def test_badge_renders_what_the_lambda_returns_for_each_attachment
    read = attach("read.pdf", "application/pdf")
    failed = attach("scan.pdf", "application/pdf")
    statuses = { read => "Read", failed => "Failed" }

    render_inline(Bali::Attachments::Component.new(
                    attachments: @workout.files,
                    badge: ->(attachment) { "<em>#{statuses[attachment]}</em>".html_safe }
                  ))

    assert_selector("li##{dom_id_for(read)} em", text: "Read")
    assert_selector("li##{dom_id_for(failed)} em", text: "Failed")
  end

  # Always in the list and shown only while it is alone, so the stream that removes the
  # last attachment brings it up with no swap of its own.
  def test_empty_text_is_an_item_that_shows_only_alone
    render_inline(Bali::Attachments::Component.new(attachments: @workout.files, empty_text: "No evidence"))

    assert_selector("ul.attachments-component > li.hidden.only\\:block", text: "No evidence", visible: :all)
  end

  def test_host_options_land_on_the_list
    attach("minutes.pdf", "application/pdf")

    render_inline(Bali::Attachments::Component.new(attachments: @workout.files, id: "evidence",
                                                   class: "mt-2"))

    assert_selector("ul#evidence.attachments-component.mt-2")
  end

  private

  def attach(filename, content_type, io: StringIO.new("%PDF-1.4"))
    @workout.files.attach(io: io, filename: filename, content_type: content_type, identify: false)
    @workout.files.reload.find { |attachment| attachment.filename.to_s == filename }
  end

  def unsaved(filename)
    Workout.new.files.attach(io: StringIO.new("%PDF-1.4"), filename: filename, content_type: "application/pdf").first
  end

  def dom_id_for(attachment)
    ActionView::RecordIdentifier.dom_id(attachment)
  end
end
