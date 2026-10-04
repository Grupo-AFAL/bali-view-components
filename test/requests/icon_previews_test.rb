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
      assert_response :ok, "/lookbook/preview/bali/icon/#{name} did not render"
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
        "#{name} listed fewer icons than its constant declares"
    end
  end

  # The static guard. A sibling constant written unqualified inside a `preview.rb` resolves against
  # the module object captured in the nesting, so it is the same #843 bomb waiting for a reload to
  # arm it — whatever component it belongs to.
  def test_no_preview_file_references_a_sibling_constant_unqualified
    offenders = preview_files.flat_map { |path| unqualified_sibling_references(path) }

    assert_empty offenders, <<~MSG
      These `preview.rb` name a sibling constant unqualified. Write it in full
      (`Bali::Icon::LucideMapping`, not `LucideMapping`) so it resolves against the module in
      force at the time of the call and not against the one `Module.nesting` captured:

      #{offenders.join("\n")}
    MSG
  end

  # The same stale nesting reaches what a preview defines inside itself — a class, a module, or a
  # constant holding one — when a method reads it: the method runs on the class Lookbook kept from
  # boot, so after a reload the short name is the copy from before it, which no longer matches the
  # new one in an `include?`, an `is_a?` or a `case` (#1303). A constant holding only values is left
  # alone: its old copy reads the same.
  def test_no_preview_method_reads_its_own_classes_unqualified
    offenders = preview_files.flat_map { |path| unqualified_own_classes_in_methods(path) }

    assert_empty offenders, <<~MSG
      These `preview.rb` read a class or module they define, or a constant holding one,
      unqualified from a method. Write it in full (`Bali::Widget::Preview::PATTERNS`, not
      `PATTERNS`): the method runs on the class Lookbook loaded at boot, and its nesting still
      points at what a reload has since replaced.

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
    # DERIVED from the engine's eager-load paths, not a copy of them: when `app/lib/bali/widget`
    # moved to `app/widgets/bali/widget`, a list written by hand here would have gone on passing
    # while the guard looked at a directory that no longer exists.
    # THE PATH RELATIVE TO ITS OWN ROOT, never `File.basename`. That shortcut is
    # only correct for a first-level `Bali::<Name>`: for `widget/list/preview.rb`
    # the basename is `list`, so it would scan `bali/list` and offer
    # `Bali::List`'s constants as siblings of `Bali::Widget::List::Preview` —
    # unrelated names, and a guard that flags them is a guard nobody trusts.
    roots = Bali::Engine.config.all_eager_load_paths.map(&:to_s)
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

  # The tree and not the token stream: what matters is whether the read sits inside a `def`.
  def unqualified_own_classes_in_methods(preview_path)
    relative = Pathname(preview_path).relative_path_from(Bali::Engine.root)
    previews = sexp_nodes(Ripper.sexp(File.read(preview_path)))
                 .select { |node| node.first == :class && defined_name(node) == "Preview" }

    previews.flat_map do |preview|
      classes = sexp_nodes(preview).filter_map { |node| defined_name(node) } - [ "Preview" ]
      own = classes + sexp_nodes(preview).filter_map { |node| constant_holding(node, classes) }

      sexp_nodes(preview).select { |node| %i[def defs].include?(node.first) }
                         .flat_map { |method| sexp_nodes(method).to_a }
                         .filter_map do |node|
        next unless node.first == :var_ref && node.dig(1, 0) == :@const

        _, name, (line, _) = node[1]
        "  #{relative}:#{line} — #{name}" if own.include?(name)
      end
    end.uniq
  end

  def defined_name(node)
    node.dig(1, 1, 1) if %i[class module].include?(node.first) && node.dig(1, 0) == :const_ref
  end

  # `NAME = …` whose right-hand side reads one of `classes`: `PATTERNS = { value: DemoValue }`.
  def constant_holding(node, classes)
    return unless node.first == :assign && node.dig(1, 0) == :var_field && node.dig(1, 1, 0) == :@const

    reads_a_class = sexp_nodes(node[2]).any? { |read| read.first == :var_ref && classes.include?(read.dig(1, 1)) }
    node.dig(1, 1, 1) if reads_a_class
  end

  def sexp_nodes(node, &block)
    return enum_for(:sexp_nodes, node) unless block
    return unless node.is_a?(Array)

    yield node if node.first.is_a?(Symbol)
    node.each { |child| sexp_nodes(child, &block) }
  end
end
