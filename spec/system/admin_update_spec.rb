# frozen_string_literal: true

require_dependency "docker_manager/git_repo"

RSpec.describe "Admin update" do
  fab!(:admin)

  before { sign_in(admin) }

  it "displays the admin update page with the right repositories" do
    visit("/admin/update")

    expect(page).to have_css("h1", exact_text: I18n.t("js.admin.docker.update_title"))
    expect(page).to have_css("tr.repo .d-table__overview-name", exact_text: "Discourse")
    expect(page).to have_css("tr.repo .d-table__overview-name", exact_text: "Docker manager")
    expect(page).to have_css(
      "tr.repo .d-table__overview-about a[href='https://meta.discourse.org/t/12655']",
    )
  end
end
