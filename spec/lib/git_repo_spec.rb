# frozen_string_literal: true

require "docker_manager/git_repo"
require_relative "../support/git_helpers"

RSpec.describe DockerManager::GitRepo do
  describe ".find_all" do
    subject { described_class.find_all }

    it "returns a list of repos" do
      expect(subject).to be_present
    end

    it "contains the `docker_manager` and `discourse` repos" do
      expect(subject.map(&:name)).to include("discourse", "docker_manager")
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

  context "with git repo" do
    def shallow_clone?
      clone_method == GitHelpers::CLONE_SHALLOW
    end

    def skip_for_shallow_clone
      pending("Doesn't work on shallow clones") if shallow_clone?
    end

    let!(:initial_branch) { "main" }

    before do
      @skip_update_remote = false
      @local_repo = @remote_git_repo = nil
      @before_local_repo_clone = []
      @after_local_repo_clone = []
    end
    after { @remote_git_repo.destroy }

    def prepare_repos
      return if @local_repo && @remote_git_repo

      @remote_git_repo = GitHelpers::RemoteGitRepo.new(initial_branch: initial_branch)
      @remote_git_repo.commit(
        filename: "foo.txt",
        commits: [
          { content: "A", date: "2023-03-06T20:31:17Z" },
          {
            content: "B",
            date: "2023-03-06T21:08:52Z",
            tags: %w[v3.1.0.beta1 beta latest-release],
          },
          { content: "C", date: "2023-03-06T22:48:29Z" },
        ],
      )
      @remote_git_repo.create_branches("tests-passed")

      @before_local_repo_clone.each { |callback| callback.call }
      @local_repo = @remote_git_repo.create_local_clone(method: clone_method)
      @after_local_repo_clone.each { |callback| callback.call }

      @remote_git_repo.in_remote_repo { |git| git.call("log --pretty=oneline") }
    end

    subject do
      prepare_repos
      repo = described_class.new(@local_repo.path)
      repo.update_remote! unless @skip_update_remote
      repo
    end

    def add_new_commits
      @remote_git_repo.commit(
        filename: "foo.txt",
        commits: [
          { content: "D", date: "2023-03-07T10:11:19Z" },
          {
            content: "E",
            date: "2023-03-07T12:58:29Z",
            tags: %w[v3.1.0.beta2 beta latest-release],
          },
          { content: "F", date: "2023-03-07T15:22:23Z" },
        ],
      )
      @remote_git_repo.rebase(source_branch: "main", target_branch: "tests-passed")
    end

    shared_examples "common tests" do
      context "when tracking `tests-passed` branch" do
        before { @after_local_repo_clone << -> { @local_repo.checkout("tests-passed") } }

        describe "#has_local_main?" do
          context "with existing `main` branch" do
            let(:initial_branch) { "main" }

            it "detects the branch" do
              expect(subject.has_local_main?).to eq(true)
            end
          end

          context "with missing `main` branch" do
            let(:initial_branch) { "master" }

            it "doesn't detect the branch" do
              expect(subject.has_local_main?).to eq(false)
            end
          end
        end

        describe "#tracking_ref" do
          it "returns the correct remote branch" do
            expect(subject.tracking_ref).to eq("origin/tests-passed")
          end

          context "with `master` as initial branch" do
            let(:initial_branch) { "master" }

            before { @after_local_repo_clone << -> { @local_repo.checkout("master") } }

            it "returns `origin/master` if a repo hasn't been renamed" do
              expect(subject.tracking_ref).to eq("origin/master")
            end

            it "returns `origin/main` if a repo has been renamed but still tracks `master`" do
              @after_local_repo_clone << -> {
                @remote_git_repo.rename_branch(old_name: "master", new_name: "main")
              }

              expect(subject.tracking_ref).to eq("origin/main")
            end
          end

          context "with `main` as current local branch" do
            before { @after_local_repo_clone << -> { @local_repo.checkout("main") } }

            it "returns `origin/main` if a repo points at `origin/main`" do
              expect(subject.tracking_ref).to eq("origin/main")
            end
          end
        end

        describe "#upstream_branch" do
          it "returns the correct branch name" do
            expect(subject.upstream_branch).to eq("origin/tests-passed")
          end
        end

        describe "#upstream_branch_exist?" do
          it "returns true when upstream branch exist" do
            expect(subject.upstream_branch_exist?).to eq(true)
          end

          it "returns false when upstream branch doesn't exist" do
            @after_local_repo_clone << -> { @remote_git_repo.delete_branches("tests-passed") }
            expect(subject.upstream_branch_exist?).to eq(false)
          end
        end

        context "when local clone and origin are the same" do
          describe "#latest_local_commit" do
            it "returns the correct commit hash" do
              expect(subject.latest_local_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash" do
              expect(subject.latest_origin_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date" do
              expect(subject.latest_local_commit_date).to eq("2023-03-06T22:48:29Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date" do
              expect(subject.latest_origin_commit_date).to eq("2023-03-06T22:48:29Z")
            end
          end

          context "with no tags" do
            before do
              @before_local_repo_clone << -> {
                @remote_git_repo.delete_tags("beta", "latest-release", "v3.1.0.beta1")
              }
            end

            describe "#latest_local_tag_version" do
              it "returns nil as version" do
                expect(subject.latest_local_tag_version).to be_nil
              end
            end

            describe "#latest_origin_tag_version" do
              it "returns nil as version" do
                expect(subject.latest_origin_tag_version).to be_nil
              end
            end
          end

          context "with `beta`, `latest-release` and version tags on HEAD~1" do
            before { skip_for_shallow_clone }

            describe "#latest_local_tag_version" do
              it "returns the correct version and ignores the `beta` tag" do
                expect(subject.latest_local_tag_version).to eq("latest-release +1")
              end
            end

            describe "#latest_origin_tag_version" do
              it "returns the correct version and ignores the `beta` and `latest-release` tags" do
                expect(subject.latest_origin_tag_version).to eq("v3.1.0.beta1 +1")
              end
            end
          end

          context "with `beta` and version tags on HEAD~1" do
            before do
              skip_for_shallow_clone
              @before_local_repo_clone << -> { @remote_git_repo.delete_tags("latest-release") }
            end

            describe "#latest_local_tag_version" do
              it "returns the correct version and ignores the `beta` tag" do
                expect(subject.latest_local_tag_version).to eq("v3.1.0.beta1 +1")
              end
            end

            describe "#latest_origin_tag_version" do
              it "returns the correct version and ignores the `beta` tag" do
                expect(subject.latest_origin_tag_version).to eq("v3.1.0.beta1 +1")
              end
            end
          end

          describe "#commits_behind" do
            it "returns 0 because local and origin are the same" do
              expect(subject.commits_behind).to eq(0)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { subject.update_remote! }.to not_change { @local_repo.commit_count }
            end
          end
        end

        context "when origin has new commits" do
          before { @after_local_repo_clone << method(:add_new_commits) }

          describe "#latest_local_commit" do
            it "returns the correct commit hash" do
              expect(subject.latest_local_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash" do
              expect(subject.latest_origin_commit).to eq("44b4ef6472e902d767335c4b19d47fd7a079d7c3")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date" do
              expect(subject.latest_local_commit_date).to eq("2023-03-06T22:48:29Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date" do
              expect(subject.latest_origin_commit_date).to eq("2023-03-07T15:22:23Z")
            end
          end

          describe "#latest_local_tag_version" do
            it "returns the correct version" do
              skip_for_shallow_clone
              expect(subject.latest_local_tag_version).to eq("v3.1.0.beta1 +1")
            end
          end

          describe "#latest_origin_tag_version" do
            it "returns the correct version and ignores the `beta` and `latest-release` tags" do
              skip_for_shallow_clone
              expect(subject.latest_origin_tag_version).to eq("v3.1.0.beta2 +1")
            end
          end

          describe "#commits_behind" do
            it "returns the correct number of commits" do
              skip_for_shallow_clone
              expect(subject.commits_behind).to eq(3)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { subject.update_remote! }.to change { @local_repo.commit_count }.by(
                fetch_commit_count,
              )
            end
          end
        end
      end

      context "when tracking `beta` tag" do
        before do
          @after_local_repo_clone << -> {
            unless shallow_clone?
              @local_repo.checkout("beta")
              # Mimics the behavior of `web.template.yml` where we store the value of the `$version` variable
              # as a user-defined config value in git.
              # See https://github.com/discourse/discourse_docker/blob/main/templates/web.template.yml
              @local_repo.git("config user.discourse-version beta")
            end
          }
        end

        describe "#has_local_main?" do
          context "with existing `main` branch" do
            let(:initial_branch) { "main" }

            it "detects the branch" do
              expect(subject.has_local_main?).to eq(true)
            end
          end

          context "with missing `main` branch" do
            let(:initial_branch) { "master" }

            it "doesn't detect the branch" do
              expect(subject.has_local_main?).to eq(false)
            end
          end
        end

        describe "#tracking_ref" do
          it "returns the correct remote branch" do
            skip_for_shallow_clone
            expect(subject.tracking_ref).to eq("beta")
          end
        end

        describe "#upstream_branch" do
          it "doesn't return a branch name" do
            skip_for_shallow_clone
            expect(subject.upstream_branch).to be_nil
          end
        end

        describe "#upstream_branch_exist?" do
          it "returns false because we aren't tracking a branch" do
            skip_for_shallow_clone
            expect(subject.upstream_branch_exist?).to eq(false)
          end
        end

        context "when local clone and origin are the same" do
          describe "#latest_local_commit" do
            it "returns the correct commit hash" do
              skip_for_shallow_clone
              expect(subject.latest_local_commit).to eq("e43b6978c22ea3aeafbcf96c6e4fff5af0b7da29")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash" do
              skip_for_shallow_clone
              expect(subject.latest_origin_commit).to eq("e43b6978c22ea3aeafbcf96c6e4fff5af0b7da29")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date" do
              skip_for_shallow_clone
              expect(subject.latest_local_commit_date).to eq("2023-03-06T21:08:52Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date" do
              skip_for_shallow_clone
              expect(subject.latest_origin_commit_date).to eq("2023-03-06T21:08:52Z")
            end
          end

          describe "#latest_local_tag_version" do
            it "returns the correct version and ignores the `beta` tag" do
              skip_for_shallow_clone
              expect(subject.latest_local_tag_version).to eq("latest-release")
            end
          end

          describe "#latest_origin_tag_version" do
            it "returns the correct version and ignores the `beta` and `latest-release` tags" do
              skip_for_shallow_clone
              expect(subject.latest_origin_tag_version).to eq("v3.1.0.beta1")
            end
          end

          describe "#commits_behind" do
            it "returns 0 because local and origin are the same" do
              expect(subject.commits_behind).to eq(0)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { subject.update_remote! }.to not_change { @local_repo.commit_count }
            end
          end
        end

        context "when origin has new commits" do
          before { @after_local_repo_clone << method(:add_new_commits) }

          describe "#latest_local_commit" do
            it "returns the correct commit hash" do
              skip_for_shallow_clone
              expect(subject.latest_local_commit).to eq("e43b6978c22ea3aeafbcf96c6e4fff5af0b7da29")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash" do
              skip_for_shallow_clone
              expect(subject.latest_origin_commit).to eq("bebd76be58db951fac6abc8d4d0746951fcd1082")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date" do
              skip_for_shallow_clone
              expect(subject.latest_local_commit_date).to eq("2023-03-06T21:08:52Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date" do
              skip_for_shallow_clone
              expect(subject.latest_origin_commit_date).to eq("2023-03-07T12:58:29Z")
            end
          end

          describe "#latest_local_tag_version" do
            it "returns the correct version" do
              skip_for_shallow_clone
              expect(subject.latest_local_tag_version).to eq("v3.1.0.beta1")
            end
          end

          describe "#latest_origin_tag_version" do
            it "returns the correct version" do
              skip_for_shallow_clone
              expect(subject.latest_origin_tag_version).to eq("v3.1.0.beta2")
            end
          end

          describe "#commits_behind" do
            it "returns the correct number of commits" do
              skip_for_shallow_clone
              expect(subject.commits_behind).to eq(3)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { subject.update_remote! }.to change { @local_repo.commit_count }.by(
                fetch_commit_count,
              )
            end
          end
        end
      end

      describe "#url" do
        before do
          @skip_update_remote = true
          @after_local_repo_clone << -> { @local_repo.git("remote set-url origin #{remote_url}") }
        end

        context "with GitHub HTTPS URL" do
          let(:remote_url) { "https://github.com/discourse/example.git" }

          it "returns the unmodified URL" do
            expect(subject.url).to eq("https://github.com/discourse/example.git")
          end
        end

        context "with GitHub SSH URL" do
          let(:remote_url) { "git@github.com:discourse/example.git" }

          it "returns a HTTPS URL" do
            expect(subject.url).to eq("https://github.com/discourse/example.git")
          end
        end

        context "with a different HTTPS URL" do
          let(:remote_url) { "https://example.com/discourse.git" }

          it "returns the unmodified URL" do
            expect(subject.url).to eq("https://example.com/discourse.git")
          end
        end

        context "with a different SSH URL" do
          let(:remote_url) { "git@example.com:discourse.git" }

          it "returns the unmodified URL" do
            expect(subject.url).to eq("git@example.com:discourse.git")
          end
        end
      end
    end

    context "with full clone" do
      let!(:clone_method) { GitHelpers::CLONE_FULL }
      let(:fetch_commit_count) { 3 }

      include_examples "common tests"
    end

    # context "with shallow clone" do
    #   let!(:clone_method) { GitHelpers::CLONE_SHALLOW }
    #   let(:fetch_commit_count) { 1 }
    #
    #   include_examples "common tests"
    # end
    #
    # context "with partial (treeless) clone" do
    #   let!(:clone_method) { GitHelpers::CLONE_TREELESS }
    #   let(:fetch_commit_count) { 3 }
    #
    #   include_examples "common tests"
    # end
  end
end
