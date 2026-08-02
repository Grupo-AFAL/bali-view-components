# frozen_string_literal: true

require "test_helper"

# The compatibility layer for `icon_name:`, and the only place in the suite where the old
# spelling is written on purpose. Everything else moved to `icon:` in the same commit, so
# nothing else would notice a shim that stopped forwarding the value, or one that stopped
# warning on the way through.
#
# All seven receivers are here, including the three whose shim predates this change
# (StatCard, DeleteLink and Dropdown#with_item): "one keyword, one deprecation" is only a
# fact if something checks it in one place.
class BaliDeprecatedIconNameTest < ComponentTestCase
  # The components whose `initialize` still declares `icon_name:`. Checked against
  # reflection below, so a component that grows the keyword and never gets a shim, or a
  # shim that is dropped from one of these, fails here rather than in a host.
  RECEIVERS = %w[
    Bali::Breadcrumb::Item::Component
    Bali::Button::Component
    Bali::DeleteLink::Component
    Bali::ImageField::Input::Component
    Bali::Link::Component
    Bali::StatCard::Component
  ].freeze

  # `Bali::Dropdown` takes the keyword through the `with_item` slot rather than through
  # `new`, so it is exercised like the rest but sits outside the reflection check.
  SLOT_RECEIVERS = %w[Bali::Dropdown::Component#with_item].freeze

  (RECEIVERS + SLOT_RECEIVERS).each do |receiver|
    slug = receiver.gsub(/\W+/, "_").downcase

    define_method("test_#{slug}_takes_icon_and_says_nothing") do
      assert_not_deprecated(Bali.deprecator) { render_receiver(receiver, icon: "star") }
      assert_selector("svg", visible: :all)
    end

    define_method("test_#{slug}_still_takes_icon_name_and_warns") do
      assert_deprecated(/`icon_name:` is deprecated/, Bali.deprecator) do
        render_receiver(receiver, icon_name: "star")
      end
      assert_selector("svg", visible: :all)
    end

    # The shim has to forward the value, not merely accept it. Byte for byte, because a
    # shim that drew *an* icon while losing, say, the wrapper class would pass anything
    # looser.
    define_method("test_#{slug}_renders_the_same_either_way") do
      render_receiver(receiver, icon: "star")
      new_way = rendered_content

      Bali.deprecator.silence { render_receiver(receiver, icon_name: "star") }

      assert_equal(new_way, rendered_content)
    end
  end

  # The list above is a list, and a list rots. Reflection over the components themselves is
  # what keeps it honest: a component that starts declaring `icon_name:` without being
  # covered here fails, and so does one whose shim is deleted a release early.
  def test_the_receivers_are_exactly_the_components_that_still_declare_icon_name
    assert_equal(RECEIVERS.sort, components_declaring_icon_name.sort, <<~MESSAGE)
      The components declaring `icon_name:` are not the ones this test covers.

      Declared: #{components_declaring_icon_name.sort.join(", ")}
      Covered:  #{RECEIVERS.sort.join(", ")}

      A new one needs a `Bali::DeprecatedIconName` shim and a line in RECEIVERS. One that
      disappeared from the left-hand side in 4.0 should disappear from RECEIVERS too.
    MESSAGE
  end

  # `icon:` and `icon_name:` together: the new keyword wins, and nothing is said, because
  # the value that would be deprecated is the one being discarded.
  def test_passing_both_keeps_the_new_keyword_and_stays_quiet
    assert_not_deprecated(Bali.deprecator) do
      render_inline(Bali::Button::Component.new(name: "Add", icon: "star", icon_name: "trash"))
    end

    render_inline(Bali::Button::Component.new(name: "Add", icon: "star"))
    only_new = rendered_content
    render_inline(Bali::Button::Component.new(name: "Add", icon: "star", icon_name: "trash"))

    assert_equal(only_new, rendered_content)
  end

  # ImageField::Input is the one with a default, so the deprecated spelling is read first
  # there. Without that ordering `icon_name:` would be unreachable rather than deprecated.
  def test_image_field_input_lets_icon_name_beat_its_default
    Bali.deprecator.silence { render_receiver("Bali::ImageField::Input::Component", icon_name: "star") }
    with_icon_name = rendered_content

    render_receiver("Bali::ImageField::Input::Component", icon: "star")

    assert_equal(rendered_content, with_icon_name)
  end

  private

  # ImageField::Input needs a real form builder to render its file field.
  def helper
    @helper ||= TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
  end

  def render_receiver(receiver, **icon)
    case receiver
    when "Bali::Breadcrumb::Item::Component"
      render_inline(Bali::Breadcrumb::Item::Component.new(name: "Home", href: "/h", **icon))
    when "Bali::Button::Component"
      render_inline(Bali::Button::Component.new(name: "Add", **icon))
    when "Bali::DeleteLink::Component"
      render_inline(Bali::DeleteLink::Component.new(href: "/d", name: "Delete", **icon))
    when "Bali::ImageField::Input::Component"
      helper.form_with(url: "/") do |form|
        render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar, **icon))
      end
    when "Bali::Link::Component"
      render_inline(Bali::Link::Component.new(name: "Edit", href: "/e", **icon))
    when "Bali::StatCard::Component"
      render_inline(Bali::StatCard::Component.new(title: "Movies", value: 20, **icon))
    when "Bali::Dropdown::Component#with_item"
      render_inline(Bali::Dropdown::Component.new) do |c|
        c.with_trigger { "Trigger" }
        c.with_item(name: "Edit", href: "/e", **icon)
      end
    else
      raise ArgumentError, "No render defined for #{receiver}"
    end
  end

  def components_declaring_icon_name
    root = Bali::Engine.root.join("app/components")

    Dir[root.join("bali/**/component.rb")].filter_map do |path|
      klass = path.delete_prefix("#{root}/").delete_suffix(".rb").camelize.safe_constantize
      next unless klass.is_a?(Class) && klass < ViewComponent::Base
      next unless declares_icon_name?(klass)

      klass.name
    end
  end

  def declares_icon_name?(klass)
    klass.instance_method(:initialize).parameters.any? do |type, name|
      name == :icon_name && %i[key keyreq].include?(type)
    end
  end
end
