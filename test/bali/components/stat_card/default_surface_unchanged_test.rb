# frozen_string_literal: true

require "test_helper"

# The fixture next to this file is the output of v3.4.0, captured before a line of
# the cell surface was written. It pins bytes, not "the same DOM": the template
# captures its body into a local, and the two ways of writing that differ only in
# whitespace.
#
# If this fails, read the diff before touching the fixture. Regenerate it only when
# the card surface is MEANT to change, and say so in the CHANGELOG.
class BaliStatCardDefaultSurfaceUnchangedTest < ComponentTestCase
  GOLDEN = File.expand_path("default_surface.golden.html", __dir__)

  # Every shape the card surface can take.
  CASES = {
    "minimal" => { title: "Total Users", value: "1,234" },
    "with_icon" => { title: "Total Users", value: "1,234", icon: "users" },
    "color_success" => { title: "Revenue", value: "$45,231", icon: "dollar-sign",
                         color: :success },
    "color_ghost" => { title: "Whatever", value: "0", icon: "users", color: :ghost },
    "custom_color" => { title: "Brand Signups", value: "312", icon: "user-plus",
                        custom_color: "#7c3aed" },
    "href" => { title: "Open Orders", value: "87", icon: "shopping-cart", color: :info,
                href: "/lookbook" },
    "numeric_value" => { title: "Count", value: 42 },
    "passthrough" => { title: "T", value: "1", icon: "users", class: "custom-class",
                       id: "stat-1", data: { testid: "stat" } },
    "card_keywords" => { title: "T", value: "1", icon: "users", shadow: false, size: :sm },
    "deprecated_icon_name" => { title: "T", value: "1", icon_name: "users" }
  }.freeze

  def test_the_card_surface_renders_the_v3_4_0_bytes
    assert_equal(File.read(GOLDEN), render_every_case)
  end

  private

  def render_every_case
    out = +""

    CASES.each do |name, attrs|
      Bali.deprecator.silence { render_inline(Bali::StatCard::Component.new(**attrs)) }
      out << "===== #{name} =====\n#{rendered_content}\n"
    end

    render_inline(Bali::StatCard::Component.new(title: "T", value: "1", icon: "users")) do |c|
      c.with_footer { "+12% from last month" }
    end
    out << "===== footer =====\n#{rendered_content}\n"

    # `href:` and the footer slot together: a link inside that footer would be an
    # `<a>` inside an `<a>`, so the docs single the combination out.
    render_inline(
      Bali::StatCard::Component.new(title: "Open Orders", value: "87", icon: "shopping-cart",
                                    color: :info, href: "/lookbook")
    ) do |c|
      c.with_footer { "+12% from last month" }
    end
    out << "===== href_with_footer =====\n#{rendered_content}\n"
  end
end
