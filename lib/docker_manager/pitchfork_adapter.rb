# frozen_string_literal: true

module DockerManager
  class PitchforkAdapter < WebServerAdapter
    def server_name
      "Pitchfork"
    end

    def launcher_pid
      `pgrep -f unicorn_launcher`.strip.to_i
    end

    def master_pid
      `pgrep -f "pitchfork monitor"`.strip.to_i
    end
  end
end
