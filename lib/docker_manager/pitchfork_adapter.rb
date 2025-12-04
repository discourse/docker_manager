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

    def workers
      `pgrep -f -P #{master_pid} worker`.split("\n").map(&:to_i)
    end

    def reload(launcher_pid, logger)
      logger.call("Restarting #{server_name} pid: #{launcher_pid}")
      original_master_pid = master_pid
      Process.kill("USR2", launcher_pid)

      # Wait for the original master to exit (it will spawn a new one)
      iterations = 0
      while pid_exists?(original_master_pid)
        iterations += 1
        break if iterations >= 60
        logger.call("Waiting for #{server_name} to reload#{"." * iterations}")
        sleep 2
      end

      # Wait for workers to be ready
      iterations = 0
      while `curl -s #{local_web_url}` != "ok"
        iterations += 1
        break if iterations >= 60
        logger.call("Waiting for #{server_name} workers to be ready#{"." * iterations}")
        sleep 2
      end
    end

    def pause_sidekiq
      false
    end

    def min_workers
      1
    end
  end
end
