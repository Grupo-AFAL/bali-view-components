# frozen_string_literal: true

require "test_helper"

# `Bali::Card::Component` already emits its own `.card-body` (`component.html.erb:4`) and accepts
# `body_class:` for whatever extra classes the call site wants. A preview that also writes its own
# `<div class="card-body">` leaves the content inside two of them, and the padding doubles: daisyUI
# declares `.card-body { padding: var(--card-p, 1.5rem) }` and nobody sets `--card-p` at the `md`
# size, so the card came out at 48px a side instead of 24px (#833).
#
# It goes over HTTP and not through a component `assert_selector`, on purpose: the defect lives in
# the preview's composition, not in the component. A component test renders `Bali::Card::Component`
# on its own and always sees a single `.card-body`, so it would never see this. And a preview is
# what a host copies, which is what makes it worth pinning.
class NestedCardBodyTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[
    /lookbook/preview/bali/dashboard_page/default
    /lookbook/preview/bali/form_page/default
    /lookbook/preview/bali/form_page/with_sidebar
  ].freeze

  def test_no_preview_nests_one_card_body_inside_another
    PREVIEWS.each do |path|
      get path
      assert_response :ok, "#{path} no renderizó"
      assert_select ".card-body", { minimum: 1 },
        "#{path} renderizó sin ningún .card-body: el test pasaría en vacío"
      assert_select ".card-body .card-body", false,
        "#{path} anida un .card-body dentro de otro — padding doble (#833)"
    end
  end

  # The request test above pins three previews. This pins the RULE: `Bali::Card::Component` is the
  # only thing allowed to write `card-body`, and none of the package's ~464 previews has any business
  # writing one by hand. It is instantaneous, so a new preview is covered without anybody remembering
  # to add it to `PREVIEWS`.
  def test_no_preview_template_writes_a_card_body_by_hand
    root = Bali::Engine.root.join("app/components/bali")
    offenders = Dir[root.join("**/previews/*.erb")].select do |file|
      File.read(file).include?("card-body")
    end

    assert_empty offenders.map { |f| f.delete_prefix("#{Bali::Engine.root}/") },
      "escriben `card-body` a mano; usá el `body_class:` de Bali::Card::Component"
  end
end
