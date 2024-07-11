# frozen_string_literal: true

require_dependency "docker_manager/git_repo"

RSpec.describe "Admin update", type: :system do
  fab!(:admin)
  let(:admin_update_page) { PageObjects::Pages::AdminUpdate.new }

  before { sign_in(admin) }

  it "displays the admin update page with the right respositories" do
    visit("/admin/update")

    # We are getting a blank page on CI so adding debugging steps to figure out why
    if ENV["CI"]
      expect(page).to have_current_path("/admin/update")
      puts page.html
    end

    expect(page).to have_css("h3", exact_text: I18n.t("js.admin.docker.update_title"))
    expect(page).to have_css("tr.repo .repo__name", exact_text: "Discourse")
    expect(page).to have_css("tr.repo .repo__name", exact_text: "Docker Manager")
    expect(page).to have_css("tr.repo .repo__about a[href='https://meta.discourse.org/t/12655']")
  end
end
