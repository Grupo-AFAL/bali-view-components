# frozen_string_literal: true

require "test_helper"
require "json"

# Every app installs Bali from git, and Yarn 4 packs a git dependency before installing
# it, with the package manager the dependency declares. A Yarn 2+ project is packed with
# `yarn pack --install-if-needed`, which first installs all of Bali's devDependencies --
# Cypress and its binary included -- inside every app as soon as a pack script exists. A
# Yarn 1 project gets that install whatever its scripts. Yarn 1 apps take the same detour
# for `prepare` once the repository is private and they clone it; Yarn 4 never runs it.
class BaliGitDependencyContractTest < ActiveSupport::TestCase
  PACKAGE_JSON = JSON.parse(Bali::Engine.root.join("package.json").read)
  SCRIPTS = PACKAGE_JSON.fetch("scripts", {})

  def test_no_pack_script_makes_a_yarn_4_host_install_bali_to_pack_it
    assert_empty SCRIPTS.keys & %w[prepack postpack],
                 "a Yarn 4 host would run a full install of Bali's devDependencies, Cypress and " \
                 "its binary included, to pack Bali"
  end

  def test_no_prepare_script_makes_a_yarn_1_host_install_bali_to_pack_it
    refute SCRIPTS.key?("prepare"),
           "a Yarn 1 host cloning Bali would run a full install of Bali's devDependencies, " \
           "Cypress included, to pack it -- and Yarn 4 never runs `prepare` in this repository"
  end

  def test_yarn_4_packs_bali_as_a_yarn_2_project
    assert_match(/\Ayarn@(?!1\.)\d+\./, PACKAGE_JSON["packageManager"].to_s,
                 "a Yarn 4 host would pack Bali as a Yarn 1 project, after a full install of its " \
                 "devDependencies, Cypress and its binary included")
  end
end
