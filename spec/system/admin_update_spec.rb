# frozen_string_literal: true

require_dependency "docker_manager/git_repo"

RSpec.describe "Admin update", type: :system do
  fab!(:admin)
  let(:admin_update_page) { PageObjects::Pages::AdminUpdate.new }

  before { sign_in(admin) }

  xit "displays the admin update page with the right respositories" do
    visit("/admin/update")

    expect(page).to have_css("h3", exact_text: I18n.t("js.admin.docker.update_title"))
    expect(page).to have_css("tr.repo .d-admin-row__overview-name", exact_text: "Discourse")
    expect(page).to have_css("tr.repo .d-admin-row__overview-name", exact_text: "Docker Manager")
    expect(page).to have_css(
      "tr.repo .d-admin-row__overview-about a[href='https://meta.discourse.org/t/12655']",
    )
  ensure
    puts page.html if ENV["CI"]
  end
end
