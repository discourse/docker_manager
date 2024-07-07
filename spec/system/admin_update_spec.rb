# frozen_string_literal: true

require_dependency "docker_manager/git_repo"

RSpec.describe "Admin update", type: :system do
  fab!(:admin)
  let(:au_page) { PageObjects::Pages::AdminUpdate.new }

  before do
    sign_in(admin)
    au_page.visit
  end

  it "shows the update page" do
    expect(au_page).to be_displayed
  end

  it "shows the core repo" do
    expect(au_page).to have_repo(
      name: "Discourse",
      url: DockerManager::GitRepo.new(Rails.root.to_s, "discourse").url,
    )
  end

  it "shows the docker_manager plugin repo" do
    expect(au_page).to have_repo(name: "Docker_manager", url: "https://meta.discourse.org/t/12655")
  end
end
