# frozen_string_literal: true

require "test_helper"

class BaliEmptyStateComponentTest < ComponentTestCase
  def test_renders_centered_container_with_title
    render_inline(Bali::EmptyState::Component.new(title: "No projects"))
    assert_selector("div.empty-state-component.flex.flex-col.items-center.justify-center")
    assert_selector(".empty-state-component p.font-medium.text-base-content", text: "No projects")
  end

  def test_renders_description_when_given
    render_inline(Bali::EmptyState::Component.new(title: "No projects", description: "Create one to get started"))
    assert_selector(".empty-state-component p.text-base-content\\/60", text: "Create one to get started")
  end

  def test_omits_description_when_not_given
    render_inline(Bali::EmptyState::Component.new(title: "No projects"))
    assert_no_selector(".empty-state-component p.text-base-content\\/60")
  end

  def test_renders_icon_inside_soft_circle_when_given
    render_inline(Bali::EmptyState::Component.new(title: "No projects", icon: "inbox"))
    assert_selector(".empty-state-component div.rounded-full.bg-base-200 svg")
  end

  def test_omits_icon_circle_when_no_icon
    render_inline(Bali::EmptyState::Component.new(title: "No projects"))
    assert_no_selector(".empty-state-component .rounded-full")
  end

  def test_default_size_applies_py8
    render_inline(Bali::EmptyState::Component.new(title: "No projects"))
    assert_selector("div.empty-state-component.py-8")
  end

  def test_lg_size_applies_py12_and_bigger_icon_circle
    render_inline(Bali::EmptyState::Component.new(title: "No projects", icon: "inbox", size: :lg))
    assert_selector("div.empty-state-component.py-12")
    assert_selector(".empty-state-component .rounded-full.size-16")
  end

  def test_sm_size_applies_py4
    render_inline(Bali::EmptyState::Component.new(title: "No projects", size: :sm))
    assert_selector("div.empty-state-component.py-4")
  end

  def test_unknown_size_falls_back_to_md
    render_inline(Bali::EmptyState::Component.new(title: "No projects", size: :huge))
    assert_selector("div.empty-state-component.py-8")
  end

  def test_renders_cta_slot
    render_inline(Bali::EmptyState::Component.new(title: "No projects")) do |empty_state|
      empty_state.with_cta { '<a href="/new" class="btn">New project</a>'.html_safe }
    end
    assert_selector(".empty-state-component a.btn[href='/new']", text: "New project")
  end

  def test_omits_cta_when_slot_not_used
    render_inline(Bali::EmptyState::Component.new(title: "No projects"))
    assert_no_selector(".empty-state-component a")
  end

  def test_html_options_passthrough_merges_class_and_sets_attributes
    render_inline(Bali::EmptyState::Component.new(title: "No projects", id: "projects-empty", class: "mt-4"))
    assert_selector("div#projects-empty.empty-state-component.mt-4.py-8")
  end
end
