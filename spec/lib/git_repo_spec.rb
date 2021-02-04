# frozen_string_literal: true

require 'rails_helper'
require 'docker_manager/git_repo'

RSpec.describe DockerManager::GitRepo do

  describe ".find_all" do
    it "returns a list of repos" do
      expect(described_class.find_all).to be_present
    end
  end

  describe ".find" do
    it "does not find invalid repos" do
      expect(described_class.find(" NOT A REPO")).to be_blank
    end

    it "returns valid repos" do
      repo = described_class.find_all.first
      expect(repo.path).to be_present
    end
  end

  describe "#branch" do

    it "returns origin/master if a repo hasn't been renamed" do
      described_class.any_instance.stubs(:upstream_branch).returns("origin/master")
      described_class.any_instance.stubs(:has_origin_main?).returns(false)
      repo = described_class.new("dummy", "dummy")
      expect(repo.branch).to eq("origin/master")
    end

    it "returns origin/main if a repo has been renamed but still tracks master" do
      described_class.any_instance.stubs(:upstream_branch).returns("origin/master")
      described_class.any_instance.stubs(:has_origin_main?).returns(true)
      repo = described_class.new("dummy", "dummy")
      expect(repo.branch).to eq("origin/main")
    end

    it "returns origin/main if a repo points at origin/main" do
      described_class.any_instance.stubs(:upstream_branch).returns("origin/main")
      described_class.any_instance.stubs(:has_origin_main?).returns(true)
      repo = described_class.new("dummy", "dummy")
      expect(repo.branch).to eq("origin/main")
    end

  end
end
