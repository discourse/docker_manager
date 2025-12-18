# frozen_string_literal: true

require "docker_manager/git_repo"
require "docker_manager/upgrader"

RSpec.describe DockerManager::Upgrader do
  subject(:upgrader) { described_class.new(user.id, repo, from_version) }

  fab!(:user, :admin)

  let(:repo_path) { Rails.root.to_s }
  let(:from_version) { "2025.12" }
  let(:repo) do
    instance_double(
      DockerManager::GitRepo,
      path: repo_path,
      name: "discourse",
      start_upgrading: true,
      stop_upgrading: true,
      latest_local_commit: "2025.12",
      tracking_ref: "origin/main",
      upstream_branch: "origin/main",
      has_local_main?: true,
      detached_head?: false,
    )
  end

  describe "#web_server" do
    context "when unicorn is running" do
      before do
        allow_any_instance_of(Kernel).to receive(:`).with("pgrep -f '^unicorn[^_]'").and_return(
          "1234",
        )
      end

      it "uses UnicornAdapter" do
        expect(upgrader.web_server).to be_a_kind_of(DockerManager::UnicornAdapter)
      end
    end

    context "when pitchfork is running" do
      before do
        allow_any_instance_of(Kernel).to receive(:`).with("pgrep -f '^unicorn[^_]'").and_return("")
      end

      it "uses PitchforkAdapter" do
        expect(upgrader.web_server).to be_a_kind_of(DockerManager::PitchforkAdapter)
      end
    end
  end

  describe "#upgrade" do
    let(:launcher_pid) { 1000 }
    let(:master_pid) { 1001 }
    let(:workers) { [2001, 2002, 2003] }

    before do
      allow_any_instance_of(Kernel).to receive(:`).with(/pgrep/).and_return("")
      allow(Open3).to receive(:popen2e).and_yield([], [], OpenStruct.new(value: 0))
      allow(upgrader.web_server).to receive_messages(
        launcher_pid:,
        master_pid:,
        workers:,
        scale_down_workers: nil,
        reload: nil,
        clear_restart_flag: nil,
        scale_up_workers: nil,
      )
    end

    context "when a repo fails to start upgrading" do
      before { allow(repo).to receive(:start_upgrading).and_return(false) }

      it "aborts the upgrade" do
        expect { upgrader.upgrade }.not_to change { Discourse.redis.get(upgrader.logs_key) }
      end
    end

    context "when not enough workers are running" do
      let(:workers) { [2001] }

      it "raises an error" do
        expect { upgrader.upgrade }.to raise_error("Not enough workers")
      end
    end

    context "when launcher process is missing" do
      let(:launcher_pid) { 0 }

      it "raises an error" do
        expect { upgrader.upgrade }.to raise_error("No Pitchfork master or launcher")
      end
    end

    context "when master process is missing" do
      let(:master_pid) { 0 }

      it "raises an error" do
        expect { upgrader.upgrade }.to raise_error("No Pitchfork master or launcher")
      end
    end

    context "with valid configuration" do
      it "scales down workers" do
        upgrader.upgrade
        expect(upgrader.web_server).to have_received(:scale_down_workers).with(2)
      end

      it "reloads the web server to free memory" do
        upgrader.upgrade
        expect(upgrader.web_server).to have_received(:reload).twice
      end

      it "runs git fetch and reset commands" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(a_kind_of(Hash), /git fetch/).ordered
        expect(Open3).to have_received(:popen2e).with(a_kind_of(Hash), /git reset --hard/).ordered
      end

      it "runs bundle install" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /bundle install --retry 3 --jobs 4/,
        )
      end

      it "runs database migrations" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /SKIP_POST_DEPLOYMENT_MIGRATIONS=1 bundle exec rake multisite:migrate/,
        ).ordered
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /&& bundle exec rake multisite:migrate/,
        ).ordered
      end

      it "compiles assets" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /bundle exec rake themes:update assets:precompile/,
        )
      end

      it "logs the version upgrade" do
        expect { upgrader.upgrade }.to change {
          UserHistory.where(custom_type: "discourse_update").count
        }.by(1)
      end

      it "sets status to complete when done" do
        expect { upgrader.upgrade }.to change { upgrader.last_status }.to "complete"
      end

      it "clears the restart flag" do
        upgrader.upgrade
        expect(upgrader.web_server).to have_received(:clear_restart_flag)
      end
    end

    context "when handling branch rename from master to main" do
      before do
        allow(repo).to receive_messages(
          upstream_branch: "origin/master",
          tracking_ref: "origin/main",
        )
      end

      context "when local main branch exists" do
        before { allow(repo).to receive(:has_local_main?).and_return(true) }

        it "checks out main branch" do
          upgrader.upgrade
          expect(Open3).to have_received(:popen2e).with(a_kind_of(Hash), /git checkout main/)
        end
      end

      context "when local main branch does not exist" do
        before { allow(repo).to receive(:has_local_main?).and_return(false) }

        it "renames master to main" do
          upgrader.upgrade
          expect(Open3).to have_received(:popen2e).with(
            a_kind_of(Hash),
            /git branch -m master main/,
          )
        end
      end
    end

    context "when repo is in detached head state" do
      before { allow(repo).to receive(:detached_head?).and_return(true) }

      it "checks out the tracking ref directly" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /git -c advice.detachedHead=false checkout/,
        )
      end
    end

    context "when S3 assets are configured" do
      before do
        ENV.merge!(
          "DISCOURSE_USE_S3" => "true",
          "DISCOURSE_S3_BUCKET" => "my-bucket",
          "DISCOURSE_S3_CDN_URL" => "https://cdn.example.com",
        )
      end

      it "uploads assets to S3" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /bundle exec rake s3:upload_assets/,
        )
      end

      it "expires missing assets from S3" do
        upgrader.upgrade
        expect(Open3).to have_received(:popen2e).with(
          a_kind_of(Hash),
          /bundle exec rake s3:expire_missing_assets/,
        )
      end
    end

    context "when an error occurs during upgrade" do
      before do
        allow(Open3).to receive(:popen2e).with(
          a_kind_of(Hash),
          /bundle install --retry 3 --jobs 4/,
        ).and_raise(RuntimeError)
      end

      it "sets status to failed" do
        expect { upgrader.upgrade }.to raise_error(RuntimeError)
        expect(upgrader.last_status).to eq("failed")
      end

      it "stops upgrading for all repos" do
        expect { upgrader.upgrade }.to raise_error(RuntimeError)
        expect(repo).to have_received(:stop_upgrading)
      end

      it "scales workers back up" do
        expect { upgrader.upgrade }.to raise_error(RuntimeError)
        expect(upgrader.web_server).to have_received(:scale_up_workers).with(2)
      end
    end
  end
end
