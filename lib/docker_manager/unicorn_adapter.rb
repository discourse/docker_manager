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
      `ps aux | grep "unicorn master -E" | grep -v "grep" | awk '{print $2}'`.strip.to_i
    end

    def workers
      `ps -f --ppid #{master_pid} | grep worker | awk '{ print $2 }'`.split("\n").map(&:to_i)
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

      # Wait for new workers to be ready
      iterations = 0
      while `curl -s #{local_web_url}` != "ok"
        iterations += 1
        break if iterations >= 60
        logger.call("Waiting for #{server_name} workers to start up#{"." * iterations}")
        sleep 2
      end
    end

    def pause_sidekiq
      return false if ENV["UNICORN_SIDEKIQS"].to_i <= 0

      Process.kill("TSTP", master_pid)
      sleep 1
      # Older versions do not have support, so quickly send a CONT so master process is not hung
      Process.kill("CONT", master_pid)
      true
    end

    def min_workers
      2
    end
  end
end
