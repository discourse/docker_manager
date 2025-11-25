# frozen_string_literal: true

RSpec.shared_examples "a web server adapter" do
  subject(:adapter) { described_class.new(upgrader) }

  let(:upgrader) { instance_double(DockerManager::Upgrader, log: nil) }

  describe "#workers" do
    before do
      allow(adapter).to receive(:master_pid).and_return(1001)
      allow_any_instance_of(Kernel).to receive(:`).with("pgrep -f -P 1001 worker").and_return(
        "2001\n2002\n2003\n",
      )
    end

    it "returns array of worker PIDs" do
      expect(adapter.workers).to contain_exactly(2001, 2002, 2003)
    end
  end

  describe "#min_workers" do
    it "returns at least 1" do
      expect(adapter.min_workers).to be >= 1
    end
  end

  describe "#local_web_url" do
    context "when UNICORN_PORT is set" do
      before { allow(ENV).to receive(:[]).with("UNICORN_PORT").and_return("8080") }

      it "uses the configured port" do
        expect(adapter.local_web_url).to eq("http://127.0.0.1:8080/srv/status")
      end
    end

    context "when UNICORN_PORT is not set" do
      it "defaults to port 3000" do
        expect(adapter.local_web_url).to eq("http://127.0.0.1:3000/srv/status")
      end
    end
  end

  describe "#scale_down_workers" do
    let(:master_pid) { 1234 }

    before do
      allow(adapter).to receive(:master_pid).and_return(master_pid)
      allow(Process).to receive(:kill)
    end

    it "sends TTOU signal to master for each worker to scale down" do
      adapter.scale_down_workers(3)
      expect(Process).to have_received(:kill).with("TTOU", master_pid).thrice
    end
  end

  describe "#scale_up_workers" do
    let(:master_pid) { 1234 }

    before do
      allow(adapter).to receive(:master_pid).and_return(master_pid)
      allow(Process).to receive(:kill)
    end

    it "sends TTIN signal to master for each worker to scale up" do
      adapter.scale_up_workers(2)
      expect(Process).to have_received(:kill).with("TTIN", master_pid).twice
    end
  end

  describe "#set_restart_flag" do
    it "sets the server restart flag through redis" do
      expect { adapter.set_restart_flag }.to change {
        Discourse.redis.get(DockerManager::WebServerAdapter::RESTART_FLAG_KEY)
      }.to("1")
    end
  end

  describe "#clear_restart_flag" do
    before { adapter.set_restart_flag }

    it "deletes the server restart flag in redis" do
      expect { adapter.clear_restart_flag }.to change {
        Discourse.redis.get(DockerManager::WebServerAdapter::RESTART_FLAG_KEY)
      }.to be_nil
    end
  end

  describe "#reload" do
    let(:launcher_pid) { 1000 }
    let(:master_pid) { 1001 }
    let(:server_name) { adapter.server_name }

    before do
      allow(adapter).to receive_messages(
        launcher_pid:,
        master_pid:,
        set_restart_flag: "OK",
        clear_restart_flag: nil,
      )
      allow(adapter).to receive(:sleep)
      allow(adapter).to receive(:`).and_return("ok")
      allow(Process).to receive(:kill)
      allow(Process).to receive(:getpgid).and_raise(Errno::ESRCH)
    end

    it "sets the restart flag before reloading" do
      adapter.reload
      expect(adapter).to have_received(:set_restart_flag).ordered
      expect(Process).to have_received(:kill).with("USR2", launcher_pid).ordered
    end

    it "logs the restart action" do
      adapter.reload
      expect(upgrader).to have_received(:log).with("Restarting #{server_name} pid: #{launcher_pid}")
    end

    it "sends USR2 signal to launcher" do
      adapter.reload
      expect(Process).to have_received(:kill).with("USR2", launcher_pid)
    end

    it "waits for original master to exit" do
      call_count = 0
      allow(Process).to receive(:getpgid).with(master_pid) do
        call_count += 1
        raise Errno::ESRCH if call_count > 2
        true
      end

      adapter.reload
      expect(adapter).to have_received(:sleep).with(2).twice
    end

    it "waits for workers to respond to health check" do
      call_count = 0
      allow(adapter).to receive(:`).with(/curl/) do
        call_count += 1
        call_count > 3 ? "ok" : "not ready"
      end

      adapter.reload
      expect(adapter).to have_received(:sleep).with(2).thrice
    end

    it "clears the restart flag after successful reload" do
      adapter.reload
      expect(adapter).to have_received(:clear_restart_flag)
    end
  end
end
