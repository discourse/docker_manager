# frozen_string_literal: true

require "docker_manager/upgrader"

RSpec.describe DockerManager::UnicornAdapter do
  subject(:adapter) { described_class.new(upgrader) }

  let(:upgrader) { instance_double(DockerManager::Upgrader, log: nil) }

  before { allow_any_instance_of(Kernel).to receive(:`) }

  it_behaves_like "a web server adapter"

  describe "#server_name" do
    it "returns 'Unicorn'" do
      expect(adapter.server_name).to eq("Unicorn")
    end
  end

  describe "#launcher_pid" do
    before do
      allow_any_instance_of(Kernel).to receive(:`).with("pgrep -f unicorn_launcher").and_return(
        "1234\n",
      )
    end

    it "returns the pid of the 'unicorn_launcher' process" do
      expect(adapter.launcher_pid).to eq(1234)
    end
  end

  describe "#master_pid" do
    before do
      allow_any_instance_of(Kernel).to receive(:`).with('pgrep -f "unicorn master -E"').and_return(
        "5678\n",
      )
    end

    it "returns the pid of the Unicorn master process" do
      expect(adapter.master_pid).to eq(5678)
    end
  end
end
