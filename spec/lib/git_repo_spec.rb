# frozen_string_literal: true

require "docker_manager/git_repo"
require_relative "../support/git_helpers"

RSpec.describe DockerManager::GitRepo do
  describe ".find_all" do
    subject(:all_repos) { described_class.find_all }

    it "returns a list of repos" do
      expect(all_repos).to be_present
    end

    it "contains the `docker_manager` and `discourse` repos" do
      expect(all_repos.map(&:name)).to include("discourse", "docker_manager")
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

    subject(:repo) do
      prepare_repos
      repo = described_class.new(@local_git_repo.path)
      repo.update_remote! unless @skip_update_remote
      repo
    end

    let!(:initial_branch) { "main" }

    before do
      @skip_update_remote = false
      @local_git_repo = @remote_git_repo = nil
      @before_local_repo_clone = []
      @after_local_repo_clone = []
    end

    after { @remote_git_repo.destroy }

    def prepare_repos
      return if @local_git_repo && @remote_git_repo

      cache_key =
        Digest::SHA1.hexdigest(
          "#{initial_branch}-" + @before_local_repo_clone.map(&:source_location).flatten.join(","),
        )

      @remote_git_repo =
        GitHelpers::RemoteGitRepo.new(initial_branch:, cache_key:) do |repo|
          repo.commit(
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

          repo.create_branches("tests-passed")

          @before_local_repo_clone.each { |callback| callback.call(repo) }
        end

      @local_git_repo = @remote_git_repo.create_local_clone(method: clone_method)
      @after_local_repo_clone.each { |callback| callback.call(@remote_git_repo, @local_git_repo) }

      @remote_git_repo.in_remote_repo { |git| git.call("log --pretty=oneline") }
    end

    def add_new_commits(remote_repo, local_repo)
      remote_repo.commit(
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
      remote_repo.rebase(source_branch: "main", target_branch: "tests-passed")
    end

    shared_examples "common tests" do |shallow_clone|
      context "when tracking `tests-passed` branch" do
        before do
          @after_local_repo_clone << ->(remote_repo, local_repo) do
            local_repo.checkout("tests-passed")
          end
        end

        describe "#has_local_main?" do
          context "with existing `main` branch" do
            let(:initial_branch) { "main" }

            it "detects the branch" do
              expect(repo.has_local_main?).to eq(true)
            end
          end

          context "with missing `main` branch" do
            let(:initial_branch) { "master" }

            it "doesn't detect the branch" do
              expect(repo.has_local_main?).to eq(false)
            end
          end
        end

        describe "#tracking_ref" do
          it "returns the correct remote branch" do
            expect(repo.tracking_ref).to eq("origin/tests-passed")
          end

          context "with `master` as initial branch" do
            let(:initial_branch) { "master" }

            before do
              @after_local_repo_clone << ->(remote_repo, local_repo) do
                local_repo.checkout("master")
              end
            end

            it "returns `origin/master` if a repo hasn't been renamed" do
              expect(repo.tracking_ref).to eq("origin/master")
            end

            it "returns `origin/main` if a repo has been renamed but still tracks `master`" do
              @after_local_repo_clone << ->(remote_repo, local_repo) do
                remote_repo.rename_branch(old_name: "master", new_name: "main")
              end

              expect(repo.tracking_ref).to eq("origin/main")
            end
          end

          context "with `main` as current local branch" do
            before do
              @after_local_repo_clone << ->(remote_repo, local_repo) { local_repo.checkout("main") }
            end

            it "returns `origin/main` if a repo points at `origin/main`" do
              expect(repo.tracking_ref).to eq("origin/main")
            end
          end
        end

        describe "#upstream_branch" do
          it "returns the correct branch name" do
            expect(repo.upstream_branch).to eq("origin/tests-passed")
          end

          context "with `master` as initial branch" do
            let(:initial_branch) { "master" }

            before do
              @after_local_repo_clone << ->(remote_repo, local_repo) do
                local_repo.checkout("master")
              end
            end

            it "returns `origin/master` if a repo hasn't been renamed" do
              expect(repo.upstream_branch).to eq("origin/master")
            end

            it "returns `origin/master` if a repo has been renamed but still tracks `master`" do
              @after_local_repo_clone << ->(remote_repo, local_repo) do
                remote_repo.rename_branch(old_name: "master", new_name: "main")
              end

              expect(repo.upstream_branch).to eq("origin/master")
            end
          end

          context "with `main` as current local branch" do
            before do
              @after_local_repo_clone << ->(remote_repo, local_repo) { local_repo.checkout("main") }
            end

            it "returns `origin/main` if a repo points at `origin/main`" do
              expect(repo.upstream_branch).to eq("origin/main")
            end
          end
        end

        describe "#upstream_branch_exist?" do
          it "returns true when upstream branch exist" do
            expect(repo.upstream_branch_exist?).to eq(true)
          end

          it "returns false when upstream branch doesn't exist" do
            @after_local_repo_clone << ->(remote_repo, local_repo) do
              remote_repo.delete_branches("tests-passed")
            end
            expect(repo.upstream_branch_exist?).to eq(false)
          end
        end

        describe "#detached_head?" do
          it "returns false" do
            expect(repo.detached_head?).to eq(false)
          end
        end

        context "when local clone and origin are the same" do
          describe "#latest_local_commit" do
            it "returns the correct commit hash" do
              expect(repo.latest_local_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash" do
              expect(repo.latest_origin_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date" do
              expect(repo.latest_local_commit_date).to eq("2023-03-06T22:48:29Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date" do
              expect(repo.latest_origin_commit_date).to eq("2023-03-06T22:48:29Z")
            end
          end

          context "with no tags" do
            before do
              @before_local_repo_clone << ->(repo) do
                repo.delete_tags("beta", "latest-release", "v3.1.0.beta1")
              end
            end

            describe "#latest_local_tag_version" do
              it "returns nil as version" do
                expect(repo.latest_local_tag_version).to be_nil
              end
            end

            describe "#latest_origin_tag_version" do
              it "returns nil as version" do
                expect(repo.latest_origin_tag_version).to be_nil
              end
            end
          end

          context "with `beta`, `latest-release` and version tags on HEAD~1", if: !shallow_clone do
            describe "#latest_local_tag_version" do
              it "returns the correct version and ignores the `beta` tag" do
                expect(repo.latest_local_tag_version).to eq("latest-release +1")
              end
            end

            describe "#latest_origin_tag_version" do
              it "returns the correct version and ignores the `beta` and `latest-release` tags" do
                expect(repo.latest_origin_tag_version).to eq("v3.1.0.beta1 +1")
              end
            end
          end

          context "with `beta` and version tags on HEAD~1", if: !shallow_clone do
            before { @before_local_repo_clone << ->(repo) { repo.delete_tags("latest-release") } }

            describe "#latest_local_tag_version" do
              it "returns the correct version and ignores the `beta` tag" do
                expect(repo.latest_local_tag_version).to eq("v3.1.0.beta1 +1")
              end
            end

            describe "#latest_origin_tag_version" do
              it "returns the correct version and ignores the `beta` tag" do
                expect(repo.latest_origin_tag_version).to eq("v3.1.0.beta1 +1")
              end
            end
          end

          describe "#commits_behind" do
            it "returns 0 because local and origin are the same" do
              expect(repo.commits_behind).to eq(0)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { repo.update_remote! }.to not_change { @local_git_repo.commit_count }
            end
          end
        end

        context "when origin has new commits" do
          before { @after_local_repo_clone << method(:add_new_commits) }

          describe "#latest_local_commit" do
            it "returns the correct commit hash" do
              expect(repo.latest_local_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash" do
              expect(repo.latest_origin_commit).to eq("44b4ef6472e902d767335c4b19d47fd7a079d7c3")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date" do
              expect(repo.latest_local_commit_date).to eq("2023-03-06T22:48:29Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date" do
              expect(repo.latest_origin_commit_date).to eq("2023-03-07T15:22:23Z")
            end
          end

          describe "#latest_local_tag_version" do
            it "returns the correct version", if: !shallow_clone do
              expect(repo.latest_local_tag_version).to eq("v3.1.0.beta1 +1")
            end
          end

          describe "#latest_origin_tag_version", if: !shallow_clone do
            it "returns the correct version and ignores the `beta` and `latest-release` tags" do
              expect(repo.latest_origin_tag_version).to eq("v3.1.0.beta2 +1")
            end
          end

          describe "#commits_behind" do
            it "returns the correct number of commits", if: !shallow_clone do
              expect(repo.commits_behind).to eq(3)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { repo.update_remote! }.to change { @local_git_repo.commit_count }.by(
                fetch_commit_count,
              )
            end
          end
        end
      end

      context "when tracking `beta` tag" do
        before do
          @after_local_repo_clone << ->(remote_repo, local_repo) do
            unless shallow_clone?
              local_repo.checkout("beta")
              # Mimics the behavior of `web.template.yml` where we store the value of the `$version` variable
              # as a user-defined config value in git.
              # See https://github.com/discourse/discourse_docker/blob/main/templates/web.template.yml
              local_repo.git("config user.discourse-version beta")
            end
          end
        end

        describe "#has_local_main?" do
          context "with existing `main` branch" do
            let(:initial_branch) { "main" }

            it "detects the branch" do
              expect(repo.has_local_main?).to eq(true)
            end
          end

          context "with missing `main` branch" do
            let(:initial_branch) { "master" }

            it "doesn't detect the branch" do
              expect(repo.has_local_main?).to eq(false)
            end
          end
        end

        describe "#tracking_ref" do
          it "returns the correct remote branch", if: !shallow_clone do
            expect(repo.tracking_ref).to eq("beta")
          end
        end

        describe "#upstream_branch" do
          it "doesn't return a branch name", if: !shallow_clone do
            expect(repo.upstream_branch).to be_nil
          end
        end

        describe "#upstream_branch_exist?" do
          it "returns false because we aren't tracking a branch", if: !shallow_clone do
            expect(repo.upstream_branch_exist?).to eq(false)
          end
        end

        describe "#detached_head?" do
          it "returns true", if: !shallow_clone do
            expect(repo.detached_head?).to eq(true)
          end
        end

        context "when local clone and origin are the same" do
          describe "#latest_local_commit" do
            it "returns the correct commit hash", if: !shallow_clone do
              expect(repo.latest_local_commit).to eq("e43b6978c22ea3aeafbcf96c6e4fff5af0b7da29")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash", if: !shallow_clone do
              expect(repo.latest_origin_commit).to eq("e43b6978c22ea3aeafbcf96c6e4fff5af0b7da29")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date", if: !shallow_clone do
              expect(repo.latest_local_commit_date).to eq("2023-03-06T21:08:52Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date", if: !shallow_clone do
              expect(repo.latest_origin_commit_date).to eq("2023-03-06T21:08:52Z")
            end
          end

          describe "#latest_local_tag_version" do
            it "returns the correct version and ignores the `beta` tag", if: !shallow_clone do
              expect(repo.latest_local_tag_version).to eq("latest-release")
            end
          end

          describe "#latest_origin_tag_version" do
            it "returns the correct version and ignores the `beta` and `latest-release` tags",
               if: !shallow_clone do
              expect(repo.latest_origin_tag_version).to eq("v3.1.0.beta1")
            end
          end

          describe "#commits_behind" do
            it "returns 0 because local and origin are the same" do
              expect(repo.commits_behind).to eq(0)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { repo.update_remote! }.to not_change { @local_git_repo.commit_count }
            end
          end
        end

        context "when origin has new commits" do
          before { @after_local_repo_clone << method(:add_new_commits) }

          describe "#latest_local_commit" do
            it "returns the correct commit hash", if: !shallow_clone do
              expect(repo.latest_local_commit).to eq("e43b6978c22ea3aeafbcf96c6e4fff5af0b7da29")
            end
          end

          describe "#latest_origin_commit" do
            it "returns the correct commit hash", if: !shallow_clone do
              expect(repo.latest_origin_commit).to eq("bebd76be58db951fac6abc8d4d0746951fcd1082")
            end
          end

          describe "#latest_local_commit_date" do
            it "returns the correct commit date", if: !shallow_clone do
              expect(repo.latest_local_commit_date).to eq("2023-03-06T21:08:52Z")
            end
          end

          describe "#latest_origin_commit_date" do
            it "returns the correct commit date", if: !shallow_clone do
              expect(repo.latest_origin_commit_date).to eq("2023-03-07T12:58:29Z")
            end
          end

          describe "#latest_local_tag_version" do
            it "returns the correct version", if: !shallow_clone do
              expect(repo.latest_local_tag_version).to eq("v3.1.0.beta1")
            end
          end

          describe "#latest_origin_tag_version" do
            it "returns the correct version", if: !shallow_clone do
              expect(repo.latest_origin_tag_version).to eq("v3.1.0.beta2")
            end
          end

          describe "#commits_behind" do
            it "returns the correct number of commits", if: !shallow_clone do
              expect(repo.commits_behind).to eq(3)
            end
          end

          describe "#update_remote!" do
            it "fetches the correct amount of new commits" do
              prepare_repos
              expect { repo.update_remote! }.to change { @local_git_repo.commit_count }.by(
                fetch_commit_count,
              )
            end
          end
        end
      end

      context "when tracking deleted branch" do
        before do
          @before_local_repo_clone << ->(repo) do
            repo.delete_tags("beta")
            repo.create_branches("beta")
          end
          @after_local_repo_clone << ->(remote_repo, local_repo) do
            local_repo.checkout("beta")
            remote_repo.delete_branches("beta")
            remote_repo.in_working_directory do |git|
              git.call("tag -m 'latest beta release' -a beta latest-release^{}")
              git.call("push origin beta")
            end
          end
        end

        describe "#latest_local_commit" do
          it "returns the correct commit hash" do
            expect(repo.latest_local_commit).to eq("16a1d8111ff1eb6e8fc1d1b973b4fd92cacbebcc")
          end
        end

        describe "#latest_origin_commit" do
          it "returns the correct commit hash", if: !shallow_clone do
            expect(repo.latest_origin_commit).to be_nil
          end
        end

        describe "#latest_local_commit_date" do
          it "returns the correct commit date" do
            expect(repo.latest_local_commit_date).to eq("2023-03-06T22:48:29Z")
          end
        end

        describe "#latest_origin_commit_date" do
          it "returns the correct commit date", if: !shallow_clone do
            expect(repo.latest_origin_commit_date).to be_nil
          end
        end

        describe "#latest_local_tag_version" do
          it "returns the correct version", if: !shallow_clone do
            expect(repo.latest_local_tag_version).to eq("latest-release +1")
          end
        end

        describe "#latest_origin_tag_version" do
          it "returns the correct version and ignores the `beta` and `latest-release` tags" do
            expect(repo.latest_origin_tag_version).to be_nil
          end
        end

        describe "#commits_behind" do
          it "returns the correct number of commits" do
            expect(repo.commits_behind).to eq(0)
          end
        end
      end

      describe "#url" do
        before do
          @skip_update_remote = true
          @after_local_repo_clone << ->(remote_repo, local_repo) do
            local_repo.git("remote set-url origin #{remote_url}")
          end
        end

        context "with GitHub HTTPS URL" do
          let(:remote_url) { "https://github.com/discourse/example.git" }

          it "returns the unmodified URL" do
            expect(repo.url).to eq("https://github.com/discourse/example.git")
          end
        end

        context "with GitHub SSH URL" do
          let(:remote_url) { "git@github.com:discourse/example.git" }

          it "returns a HTTPS URL" do
            expect(repo.url).to eq("https://github.com/discourse/example.git")
          end
        end

        context "with a different HTTPS URL" do
          let(:remote_url) { "https://example.com/discourse.git" }

          it "returns the unmodified URL" do
            expect(repo.url).to eq("https://example.com/discourse.git")
          end
        end

        context "with a different SSH URL" do
          let(:remote_url) { "git@example.com:discourse.git" }

          it "returns the unmodified URL" do
            expect(repo.url).to eq("git@example.com:discourse.git")
          end
        end
      end
    end

    context "with full clone" do
      let!(:clone_method) { GitHelpers::CLONE_FULL }
      let(:fetch_commit_count) { 3 }

      include_examples "common tests"
    end

    context "with shallow clone" do
      let!(:clone_method) { GitHelpers::CLONE_SHALLOW }
      let(:fetch_commit_count) { 1 }

      include_examples "common tests", true
    end

    context "with partial (treeless) clone" do
      let!(:clone_method) { GitHelpers::CLONE_TREELESS }
      let(:fetch_commit_count) { 3 }

      include_examples "common tests"
    end

    context "with modern discourse-compatibility file" do
      let!(:clone_method) { GitHelpers::CLONE_SHALLOW }

      before do
        @before_local_repo_clone << ->(repo) do
          repo.commit(
            filename: ".discourse-compatibility",
            commits: [{ content: "<= 1000.0.0: twoPointFiveBranch", date: "2023-03-06T20:31:17Z" }],
          )
        end
      end

      it "works" do
        DockerManager::FallbackCompatibilityParser.expects(:find_compatible_resource).never
        expect(repo.tracking_ref).to eq("twoPointFiveBranch")
      end

      it "works even in old core" do
        Discourse
          .stubs(:find_compatible_resource)
          .with { |version_list| version_list.include?("<=") }
          .raises(ArgumentError)

        expect(repo.tracking_ref).to eq("twoPointFiveBranch")
      end
    end
  end
end
