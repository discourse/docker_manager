# frozen_string_literal: true

require_dependency "docker_manager/git_repo"

RSpec.describe "Admin update" do
  fab!(:admin)

  before do
    sign_in(admin)

    # Avoid running `git` for every repo on every request
    DockerManager::GitRepo.any_instance.stubs(:latest_origin_commit).returns("a" * 40)
    DockerManager::GitRepo.any_instance.stubs(:latest_origin_tag_version).returns(nil)
    DockerManager::GitRepo.any_instance.stubs(:commits_behind).returns(0)
    DockerManager::GitRepo.any_instance.stubs(:latest_origin_commit_date).returns(Time.current)
  end

  it "displays the admin update page with the right repositories" do
    visit("/admin/update")

    expect(page).to have_css("h1", exact_text: I18n.t("js.admin.docker.update_title"))
    expect(page).to have_css("tr.repo .d-table__overview-name", exact_text: "Discourse")
    expect(page).to have_css("tr.repo .d-table__overview-name", text: /\ADocker[ _]manager\z/)
    expect(page).to have_css(
      "tr.repo .d-table__overview-about a[href='https://meta.discourse.org/t/12655']",
    )
  end
end
