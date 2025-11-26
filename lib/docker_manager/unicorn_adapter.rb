# frozen_string_literal: true

module DockerManager
  # Adapter for managing Unicorn web server processes
  class UnicornAdapter < WebServerAdapter
    # @return [String]
    def server_name
      "Unicorn"
    end

    # @return [Integer]
    def launcher_pid
      `ps aux | grep unicorn_launcher | grep -v sudo | grep -v grep | awk '{ print $2 }'`.strip.to_i
    end

    # @return [Integer]
    def master_pid
      `ps aux | grep "unicorn master -E" | grep -v "grep" | awk '{print $2}'`.strip.to_i
    end

    # @param master_pid [Integer]
    # @return [Array<Integer>]
    def workers
      `ps -f --ppid #{master_pid} | grep worker | awk '{ print $2 }'`.split("\n").map(&:to_i)
    end

    # Reload Unicorn by sending USR2 to launcher, which spawns a new master
    # @param launcher_pid [Integer]
    # @param original_master_pid [Integer]
    # @param logger [#call]
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

    # Pause Sidekiq by sending TSTP signal to Unicorn master
    # @param master_pid [Integer]
    # @return [Boolean]
    def pause_sidekiq
      return false if ENV["UNICORN_SIDEKIQS"].to_i <= 0

      Process.kill("TSTP", master_pid)
      sleep 1
      # Older versions do not have support, so quickly send a CONT so master process is not hung
      Process.kill("CONT", master_pid)
      true
    end

    # @return [Integer]
    def min_workers
      2
    end
  end
end
