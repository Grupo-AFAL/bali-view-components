# frozen_string_literal: true

require "test_helper"

# A token that is not on the scale fails SILENTLY and the wrong way round: a host that declares
# `--bali-z-hovercard` because the guide told them to sees no error, and does not see the `9999`
# fallback either —`zIndexFor` only falls there when Bali's sheet is absent from the page— so they
# are left with the value of the tier that does exist and conclude their override "does nothing"
# without knowing why. That was #851: the migration guide's prose sent hosts off to define a token
# the gem never declared, while its own table, thirty lines above, said the right thing.
class BaliZIndexTokensTest < ActiveSupport::TestCase
  ENGINE_ROOT = Pathname.new(File.expand_path("../..", __dir__))
  SCALE = ENGINE_ROOT.join("app/assets/stylesheets/bali/z_index.css")

  # `docs/` only, and on purpose: what is guarded is that the documentation does not PROMISE a host a
  # token nobody declares. The CHANGELOG is a record of what happened —including the entry saying
  # this wrong token is gone— and naming it there is correct.
  PROSE = Dir[ENGINE_ROOT.join("docs/**/*.md")].sort.freeze

  def declared_tokens
    SCALE.read.scan(/--bali-z-([a-z-]+)\s*:/).flatten.uniq.sort
  end

  def test_the_scale_declares_the_tiers_the_package_reads
    # If this list changes, the contract changed: a tier's name is API for the host.
    assert_equal(
      %w[command drawer dropdown modal popover toast tooltip],
      declared_tokens
    )
  end

  def test_the_documentation_names_no_token_the_scale_does_not_declare
    known = declared_tokens
    offenders = PROSE.flat_map do |path|
      relative = Pathname.new(path).relative_path_from(ENGINE_ROOT)
      File.readlines(path).each_with_index.filter_map do |line, index|
        tokens = line.scan(/--bali-z-([a-z-]+)/).flatten.uniq - known
        "  #{relative}:#{index + 1} — --bali-z-#{tokens.first}" if tokens.any?
      end
    end

    assert_empty(
      offenders,
      "La documentación promete tokens que la escala no declara. Los tiers son " \
      "#{known.join(', ')}; un nombre fuera de esa lista no lo lee nadie y no avisa.\n" +
      offenders.join("\n")
    )
  end
end
