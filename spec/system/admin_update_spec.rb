# frozen_string_literal: true

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
      url: "https://github.com/discourse/discourse.git",
    )
  end

  it "shows the docker_manager plugin repo" do
    expect(au_page).to have_repo(name: "Docker Manager", url: "https://meta.discourse.org/t/12655")
  end
end
