# frozen_string_literal: true

require "test_helper"

class BaliCommandComponentTest < ComponentTestCase
  def test_renders_the_command_container_with_stimulus_controller
    render_inline(Bali::Command::Component.new)
    assert_selector(".bali-command[data-controller='command']")
  end

  def test_renders_panel_and_backdrop_targets
    render_inline(Bali::Command::Component.new)
    assert_selector("[data-command-target='panel']")
    assert_selector("[data-command-target='backdrop']")
    assert_selector("[data-command-target='input']")
  end

  def test_panel_and_backdrop_start_hidden
    render_inline(Bali::Command::Component.new)
    assert_selector("[data-command-target='panel'].hidden")
    assert_selector("[data-command-target='backdrop'].hidden")
  end

  def test_renders_default_placeholder
    render_inline(Bali::Command::Component.new)
    assert_selector("input[placeholder='Search…']")
  end

  def test_default_strings_resolve_through_locale_files
    I18n.with_locale(:es) do
      render_inline(Bali::Command::Component.new)
    end
    assert_selector("input[placeholder='Buscar…']")
    assert_text("navegar")
    assert_text("abrir")
    assert_text("cerrar")
  end

  def test_uses_custom_placeholder
    render_inline(Bali::Command::Component.new(placeholder: "Find anything"))
    assert_selector("input[placeholder='Find anything']")
  end

  def test_renders_trigger_slot
    render_inline(Bali::Command::Component.new) do |c|
      c.with_trigger { "<button>Open palette</button>".html_safe }
    end
    assert_selector("[data-action*='click->command#open']")
    assert_selector("button", text: "Open palette")
  end

  def test_renders_groups_with_items
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "Pages") do |g|
        g.with_item(title: "Dashboard", icon: "layout-dashboard", href: "/dashboard")
        g.with_item(title: "Settings", icon: "settings", href: "/settings")
      end
    end
    assert_selector("[data-command-target='group']", text: "Pages")
    assert_selector("[data-command-target='row']", count: 2)
    assert_selector(".cmd-row-title", text: "Dashboard")
    assert_selector(".cmd-row-title", text: "Settings")
  end

  def test_item_href_is_html_escaped_in_data_attribute
    # Regression: previously used `html_safe` on a string concatenation, which
    # could let an attacker inject attribute markup if href came from user input.
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "Pages") do |g|
        g.with_item(title: "Evil", href: '"><script>alert(1)</script>')
      end
    end
    # The dangerous quote should be escaped so it never breaks out of the attribute.
    refute_match(%r{<script>}, page.native.to_html)
  end

  def test_group_default_mode_is_searchable
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "Stuff") do |g|
        g.with_item(title: "X")
      end
    end
    assert_selector("[data-command-target='group'][data-mode='searchable']")
    assert_selector("[data-command-target='row'][data-mode='searchable']")
  end

  def test_group_recent_mode
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "Recents", mode: :recent) do |g|
        g.with_item(title: "Yesterday's doc")
      end
    end
    assert_selector("[data-command-target='group'][data-mode='recent']")
    assert_selector("[data-command-target='row'][data-mode='recent']")
  end

  def test_group_action_mode
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "Actions", mode: :action) do |g|
        g.with_item(title: "New")
      end
    end
    assert_selector("[data-command-target='group'][data-mode='action']")
  end

  def test_invalid_group_mode_falls_back_to_searchable
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "Bad", mode: :nonsense) do |g|
        g.with_item(title: "X")
      end
    end
    assert_selector("[data-command-target='group'][data-mode='searchable']")
  end

  def test_item_search_text_defaults_to_title_and_meta
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "G") do |g|
        g.with_item(title: "Hello", meta: "World")
      end
    end
    assert_selector("[data-search='hello world']")
  end

  def test_item_search_text_can_be_overridden
    render_inline(Bali::Command::Component.new) do |c|
      c.with_group(name: "G") do |g|
        g.with_item(title: "Hello", search: "Custom")
      end
    end
    assert_selector("[data-search='custom']")
  end

  def test_compact_density_adds_modifier_class
    render_inline(Bali::Command::Component.new(density: :compact))
    assert_selector(".cmd-panel.is-compact")
  end

  def test_default_density_omits_modifier_class
    render_inline(Bali::Command::Component.new)
    assert_no_selector(".cmd-panel.is-compact")
  end

  def test_invalid_density_falls_back_to_default
    render_inline(Bali::Command::Component.new(density: :nonsense))
    assert_no_selector(".cmd-panel.is-compact")
  end

  def test_compact_predicate
    assert(Bali::Command::Component.new(density: :compact).compact?)
    refute(Bali::Command::Component.new(density: :default).compact?)
  end

  def test_renders_no_results_message_with_default_text
    render_inline(Bali::Command::Component.new)
    assert_selector("[data-command-target='noResults']", text: "No results")
  end

  def test_renders_custom_no_results_text
    render_inline(Bali::Command::Component.new(no_results_text: "Nothing here"))
    assert_selector("[data-command-target='noResults']", text: "Nothing here")
  end

  def test_renders_no_results_subtitle_when_provided
    render_inline(Bali::Command::Component.new(no_results_subtitle: "Try another term"))
    assert_text("Try another term")
  end

  def test_omits_no_results_subtitle_when_nil
    render_inline(Bali::Command::Component.new)
    assert_no_text("Try another term")
  end

  def test_accepts_custom_classes
    render_inline(Bali::Command::Component.new(class: "my-palette"))
    assert_selector(".bali-command.my-palette")
  end
end
