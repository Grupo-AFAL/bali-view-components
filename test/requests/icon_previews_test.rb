# frozen_string_literal: true

require "test_helper"
require "ripper"

# The Icon previews 500'd with `uninitialized constant Bali::Icon::Preview::LucideMapping` (#843)
# and no test saw it, because the defect is not in the component but in how the preview file *names*
# its neighbours.
#
# `Module.nesting` is captured at parse time and holds a reference to the module object, not to the
# name. Lookbook loads `preview.rb` at boot to build its navigation, capturing the `Bali::Icon` of
# that moment; a later `reload!` discards that module and creates another, and the sibling constant
# is autoloaded inside the new one while the preview's nesting still points at the old. The constant
# exists, `bin/rails runner` resolves it, and the request dies anyway.
#
# Hence the two halves of this file: asking for the previews over HTTP —the only path where the
# defect shows — and statically forbidding the pattern in every `preview.rb`, so it does not depend
# on somebody remembering to add the request when they add a preview.
class IconPreviewsTest < ActionDispatch::IntegrationTest
  # The five that read a sibling constant, plus `default` as a control.
  PREVIEWS = %w[
    lucide_mapped_icons
    brand_icons
    regional_icons
    custom_domain_icons
    all_existing_icons
    default
  ].freeze

  def test_every_icon_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/icon/#{name}"
      assert_response :ok, "/lookbook/preview/bali/icon/#{name} no renderizó"
    end
  end

  def test_the_catalog_previews_render_their_icons_and_not_an_empty_list
    { "lucide_mapped_icons" => Bali::Icon::LucideMapping.bali_names.size,
      "brand_icons" => Bali::Icon::KeptIcons::BRAND_PAYMENT.size +
                       Bali::Icon::KeptIcons::BRAND_SOCIAL.size,
      "regional_icons" => Bali::Icon::KeptIcons::REGIONAL.size,
      "custom_domain_icons" => Bali::Icon::KeptIcons::CUSTOM.size }.each do |name, count|
      get "/lookbook/preview/bali/icon/#{name}"
      assert_response :ok
      assert_select ".icon-component", { minimum: count },
        "#{name} listó menos iconos que los que declara su constante"
    end
  end

  # The static guard. A sibling constant written unqualified inside a `preview.rb` resolves against
  # the module object captured in the nesting, so it is the same #843 bomb waiting for a reload to
  # arm it — whatever component it belongs to.
  def test_no_preview_file_references_a_sibling_constant_unqualified
    offenders = preview_files.flat_map { |path| unqualified_sibling_references(path) }

    assert_empty offenders, <<~MSG
      Estos `preview.rb` nombran una constante hermana sin calificar. Escribila completa
      (`Bali::Icon::LucideMapping`, no `LucideMapping`) para que se resuelva contra el módulo
      vigente en el momento de la llamada y no contra el que capturó `Module.nesting`:

      #{offenders.join("\n")}
    MSG
  end

  # The guard is worth little if it cannot see half the siblings. `Bali::Widget` is the gem's first
  # namespace spanning two autoload roots, and that is where it showed: `sibling_constants` only
  # looked at the preview's own directory, so it discovered `Component` and neither `Base` nor the
  # pattern classes. This test pins that it discovers them all, because the only signal one is
  # missing is a 500 on the request — never in `bin/rails runner`.
  def test_sibling_discovery_spans_both_autoload_roots
    preview = Bali::Engine.root.join("app/components/bali/widget/preview.rb").to_s
    siblings = send(:sibling_constants, preview)

    assert_includes siblings, "Component", "app/components/bali/widget/component.rb"
    assert_includes siblings, "Base", "app/widgets/bali/widget/base.rb"
    assert_includes siblings, "ListBase", "app/widgets/bali/widget/list_base.rb"
    assert_includes siblings, "TrendBase", "app/widgets/bali/widget/trend_base.rb"
  end

  private

  def preview_files
    # `**`, not `*`: a component's preview can be nested — `widget/list/preview.rb`,
    # `form/select/preview.rb` — and a single level checked 90 of 131 previews,
    # leaving every nested one free to reintroduce #843.
    Dir[Bali::Engine.root.join("app/components/bali/**/preview.rb")].sort
  end

  # The constant names Zeitwerk defines *inside* the component's namespace: a file or a directory
  # sibling to `preview.rb`.
  def sibling_constants(preview_path)
    dir = File.dirname(preview_path)
    # A component's namespace can span SEVERAL autoload roots: `Bali::Widget::Component` lives in
    # `app/components` and `Bali::Widget::Base` in `app/widgets`. Zeitwerk defines them all inside
    # the SAME module, so they are siblings alike and #843's bug applies to them alike. Looking only
    # at the preview's directory left it blind to the rest: a bare constant there passed the guard
    # and blew up on the request.
    #
    # DERIVED from `eager_load_paths`, not a copy of it: when `app/lib/bali/widget` moved to
    # `app/widgets/bali/widget`, a list written by hand here would have gone on passing while the
    # guard looked at a directory that no longer exists.
    # THE PATH RELATIVE TO ITS OWN ROOT, never `File.basename`. That shortcut is
    # only correct for a first-level `Bali::<Name>`: for `widget/list/preview.rb`
    # the basename is `list`, so it would scan `bali/list` and offer
    # `Bali::List`'s constants as siblings of `Bali::Widget::List::Preview` —
    # unrelated names, and a guard that flags them is a guard nobody trusts.
    roots = Bali::Engine.config.eager_load_paths.map(&:to_s)
    root = roots.find { |candidate| dir.start_with?("#{candidate}/") }
    relative = root ? dir.delete_prefix("#{root}/") : File.basename(dir)

    dirs = roots.map { |candidate| File.join(candidate, relative) }.uniq

    # A directory with no `.rb` inside it (`previews/`, `svg/`) is not a namespace for Zeitwerk.
    basenames = dirs.flat_map do |d|
      Dir["#{d}/*.rb"].map { |f| File.basename(f, ".rb") } +
        Dir["#{d}/*/"].select { |sub| Dir["#{sub}**/*.rb"].any? }.map { |sub| File.basename(sub) }
    end

    basenames.reject { |b| b == "preview" }
             .map { |b| b.split("_").map(&:capitalize).join }
             .uniq
  end

  # Ripper instead of a regular expression: the constant `Item` has to be told from the string
  # `'Item 1'` and from the method `with_item`, and a regex over raw text cannot.
  def unqualified_sibling_references(preview_path)
    siblings = sibling_constants(preview_path)
    return [] if siblings.empty?

    relative = Pathname(preview_path).relative_path_from(Bali::Engine.root)
    previous = nil

    Ripper.lex(File.read(preview_path)).filter_map do |(line, _col), type, token|
      was_scope_operator = previous == "::"
      previous = token unless type == :on_sp || type == :on_ignored_nl || type == :on_nl

      next if type != :on_const || was_scope_operator || !siblings.include?(token)

      "  #{relative}:#{line} — #{token}"
    end
  end
end
