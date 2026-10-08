# frozen_string_literal: true

require "test_helper"
require "json"

# Every app installs Bali from git, and Yarn 4 packs a git dependency before installing
# it, with the package manager the dependency declares. A Yarn 2+ project is packed with
# `yarn pack --install-if-needed`, which first installs all of Bali's devDependencies --
# Cypress and its binary included -- inside every app as soon as a pack script exists. A
# Yarn 1 project gets that install whatever its scripts. Yarn 1 apps take the same detour
# for `prepare` once the repository is private and they clone it.
class BaliGitDependencyContractTest < ActiveSupport::TestCase
  PACKAGE_JSON = JSON.parse(Bali::Engine.root.join("package.json").read)

  def test_no_script_makes_an_app_install_bali_to_pack_it
    assert_empty PACKAGE_JSON.fetch("scripts", {}).keys & %w[prepare prepack postpack],
                 "every app installing Bali from git would install Bali's devDependencies first"
  end

  def test_yarn_4_packs_bali_as_a_yarn_2_project
    assert_match(/\Ayarn@(?!1\.)\d+\./, PACKAGE_JSON["packageManager"].to_s,
                 "without it Yarn 4 packs Bali as a Yarn 1 project, after a full install")
  end
end
