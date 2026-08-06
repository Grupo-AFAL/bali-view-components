# frozen_string_literal: true

require "test_helper"

class BaliIconLucideMappingTest < ActiveSupport::TestCase
  def test_find_returns_lucide_name_for_mapped_bali_icon
    assert_equal("pencil", Bali::Icon::LucideMapping.find("edit"))
    assert_equal("circle-check", Bali::Icon::LucideMapping.find("check-circle"))
    assert_equal("trash", Bali::Icon::LucideMapping.find("trash-alt"))
  end

  def test_find_returns_nil_for_unmapped_icons
    assert_nil(Bali::Icon::LucideMapping.find("visa"))
    assert_nil(Bali::Icon::LucideMapping.find("nonexistent"))
  end

  def test_find_accepts_symbols
    assert_equal("pencil", Bali::Icon::LucideMapping.find(:edit))
  end

  def test_mapped_returns_true_for_mapped_icons
    assert(Bali::Icon::LucideMapping.mapped?("edit"))
    assert(Bali::Icon::LucideMapping.mapped?("plus-circle"))
  end

  def test_mapped_returns_false_for_unmapped_icons
    refute(Bali::Icon::LucideMapping.mapped?("visa"))
    refute(Bali::Icon::LucideMapping.mapped?("whatsapp"))
  end

  def test_bali_names_returns_all_bali_icon_names_that_have_mappings
    names = Bali::Icon::LucideMapping.bali_names
    assert_includes(names, "edit")
    assert_includes(names, "check-circle")
    assert_includes(names, "trash-alt")
    refute_includes(names, "visa")
    refute_includes(names, "whatsapp")
  end

  def test_lucide_names_returns_unique_lucide_names_used_in_mappings
    names = Bali::Icon::LucideMapping.lucide_names
    assert_includes(names, "pencil")
    assert_includes(names, "circle-check")
    assert_includes(names, "trash")
    assert_equal(names.size, names.uniq.size)
  end

  # Resolution consults MAPPING before trying the name as a Lucide icon, so a
  # key that is ALSO a current Lucide name and points at a different glyph
  # shadows the real icon: the honest spelling of that name becomes
  # unreachable, silently. `grid` and `file-signature` were removed for
  # exactly that pre-v3.0, and #902 removed `trash`, `cog`, `expand`,
  # `indent` and `outdent` (see REMOVED_SHADOWED_KEYS below). The keys here
  # are the deliberate survivors, frozen in BOTH directions — a new shadowing
  # entry fails this test, and removing one obliges updating the list, which
  # is the paper trail we want. Measured SVG against SVG on lucide-rails
  # 0.7.4 (what Gemfile.lock pins — the determinism comes from the lock, not
  # from the gemspec cap): `plus-circle` draws the same thing as its target;
  # `check-circle` and `edit` redirect on purpose, because their "honest"
  # spellings are deprecated Lucide aliases — a legacy glyph and a name whose
  # real rename is `square-pen`. The header of lucide_mapping.rb tells the
  # full story.
  KNOWN_SHADOWED_KEYS = %w[
    plus-circle
    check-circle edit
  ].freeze

  # The five keys #902 removed: each was shadowing a current Lucide name with
  # a different glyph. They must stay out of MAPPING, and their honest
  # spelling must keep resolving through the pipeline's step 2 — if either
  # half fails, the shadowing came back or the pinned lucide-rails dropped
  # the file, and both deserve a red build.
  REMOVED_SHADOWED_KEYS = %w[cog expand indent outdent trash].freeze

  def test_no_mapping_key_shadows_a_current_lucide_name_beyond_the_known_set
    shadowed = Bali::Icon::LucideMapping::MAPPING
                 .select { |key, target| key != target && lucide_icon?(key) }
                 .keys.sort
    assert_equal(KNOWN_SHADOWED_KEYS.sort, shadowed)
  end

  def test_removed_shadowed_keys_stay_out_of_the_mapping_and_resolve_as_lucide
    REMOVED_SHADOWED_KEYS.each do |name|
      refute(Bali::Icon::LucideMapping.mapped?(name),
             "#{name} was removed from MAPPING by #902; do not reintroduce it")
      assert(lucide_icon?(name),
             "#{name} must resolve as a direct Lucide icon (pipeline step 2)")
    end
  end

  def test_mapping_carries_no_identity_entries
    identity = Bali::Icon::LucideMapping::MAPPING.select { |key, target| key == target }.keys
    assert_empty(identity,
                 "identity entries are dead weight — the direct-Lucide step already " \
                 "resolves these names: #{identity.inspect}")
  end

  def test_mapping_constant_is_frozen
    assert(Bali::Icon::LucideMapping::MAPPING.frozen?)
  end

  def test_mapping_constant_has_string_keys
    assert(Bali::Icon::LucideMapping::MAPPING.keys.all? { |e| e.is_a?(String) })
  end

  def test_mapping_constant_has_string_values
    assert(Bali::Icon::LucideMapping::MAPPING.values.all? { |e| e.is_a?(String) })
  end

  private

  # The same predicate the resolution pipeline uses in its step 2.
  def lucide_icon?(name)
    LucideRails::IconProvider.icon(name)
    true
  rescue ArgumentError
    false
  end
end
