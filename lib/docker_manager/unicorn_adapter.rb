# frozen_string_literal: true

module DockerManager
  class UnicornAdapter < WebServerAdapter
    def server_name
      "Unicorn"
    end

    def launcher_pid
      `pgrep -f unicorn_launcher`.strip.to_i
    end

    def master_pid
      `pgrep -f "unicorn master -E"`.strip.to_i
    end
  end
end
