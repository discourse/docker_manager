# frozen_string_literal: true

RSpec.describe DockerManager::AdminController do
  describe "anonymous user" do
    it "should be a 404" do
      get "/admin/update"

      expect(response.status).to eq(404)
    end
  end

  describe "when user is not an admin" do
    it "should 404" do
      sign_in(Fabricate(:user))

      get "/admin/update"
      expect(response.status).to eq(404)
    end
  end

  describe "when user is an admin" do
    it "should return the right response" do
      sign_in(Fabricate(:admin))

      get "/admin/update"
      expect(response.status).to eq(200)
    end

    it "should redirect to the new route" do
      sign_in(Fabricate(:admin))

      get "/admin/upgrade"
      expect(response.status).to eq(301)

      uri = URI.parse(response.headers["Location"])
      expect(uri.path).to eq("/admin/update")
    end
  end

  describe "#repos" do
    before do
      # Return only the first 3 repos to reduce the number of calls to 'git' CLI
      repos = DockerManager::GitRepo.find_all
      DockerManager::GitRepo.stubs(:find_all).returns(repos[0...3])
    end

    it "should return the right response" do
      sign_in(Fabricate(:admin))

      get "/admin/docker/repos.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["repos"].first["official"]).to eq(false)
    end

    context "when the image check runs" do
      before do
        sign_in(Fabricate(:admin))
        Rails.env.stubs(:test?).returns(false)
        DockerManager::GitRepo.any_instance.stubs(:detached_head?).returns(true)
      end

      it "requires an upgrade when the base image is out of date" do
        DockerManager::BaseImage.stubs(:outdated?).returns(true)

        get "/admin/docker/repos.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["upgrade_required"]).to eq(true)
      end

      it "does not require an upgrade when the base image is current" do
        DockerManager::BaseImage.stubs(:outdated?).returns(false)

        get "/admin/docker/repos.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body).not_to have_key("upgrade_required")
      end

      it "does not require an upgrade when the base image version cannot be read" do
        DockerManager::BaseImage.stubs(:outdated?).raises(
          Discourse::Utils::CommandError.new("git fetch failed"),
        )

        get "/admin/docker/repos.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body).not_to have_key("upgrade_required")
      end
    end
  end
end
