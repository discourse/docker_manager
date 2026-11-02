# frozen_string_literal: true

require "docker_manager/base_image"
require_relative "../../support/git_helpers"

RSpec.describe DockerManager::BaseImage do
  describe ".outdated?" do
    let(:version_file) { Tempfile.new("VERSION") }

    around do |example|
      stub_const(described_class, "VERSION_FILE", version_file.path) { example.run }
    end

    before do
      allow(described_class).to receive(:expected_version).and_return(
        Gem::Version.new("2.0.20261027-1647"),
      )
    end

    after { version_file.close! }

    it "returns true when the image is older" do
      File.write(version_file.path, "2.0.20261026\n")
      expect(described_class.outdated?).to eq(true)
    end

    it "returns false when the image is from the same day" do
      File.write(version_file.path, "2.0.20261027\n")
      expect(described_class.outdated?).to eq(false)
    end

    it "returns false when the image is newer" do
      File.write(version_file.path, "2.0.20261028\n")
      expect(described_class.outdated?).to eq(false)
    end

    it "returns true without fetching when there is no version file" do
      File.delete(version_file.path)
      expect(described_class.outdated?).to eq(true)
      expect(described_class).not_to have_received(:expected_version)
    end
  end

  describe ".expected_version" do
    let(:templates) do
      [
        "base_image: discourse/base:2.0.20261026-0138\nparams:\n  version: tests-passed\n",
        "base_image: discourse/base:2.0.20261027-1647\nparams:\n  version: tests-passed\n",
      ]
    end

    let(:remote) do
      GitHelpers::RemoteGitRepo.new(
        cache_key: "base_image_#{Digest::SHA1.hexdigest(templates.join)}",
      ) do |repo|
        repo.in_working_directory { FileUtils.mkdir_p("templates") }
        repo.commit(
          filename: "templates/web.template.yml",
          commits: templates.map { |content| { content: } },
        )
      end
    end

    let(:repo_url) { remote.url }

    around { |example| stub_const(described_class, "REPO_URL", repo_url) { example.run } }

    after { remote.destroy }

    it "reads the version from the latest template on main" do
      expect(described_class.expected_version).to eq(Gem::Version.new("2.0.20261027-1647"))
    end

    context "when the template has no base_image" do
      let(:templates) { ["params:\n  version: tests-passed\n"] }

      it "raises an error" do
        expect { described_class.expected_version }.to raise_error(KeyError)
      end
    end

    context "when the repository cannot be fetched" do
      let(:repo_url) { "file:///nonexistent.git" }

      it "raises an error" do
        expect { described_class.expected_version }.to raise_error(Discourse::Utils::CommandError)
      end
    end
  end
end
