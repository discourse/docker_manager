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

end
