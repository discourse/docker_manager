# frozen_string_literal: true

module DockerManager
  # Adapter for managing Pitchfork web server processes
  class PitchforkAdapter < WebServerAdapter
    # @return [String]
    def server_name
      "Pitchfork"
    end

    # Pitchfork doesn't use a separate launcher process in the same way as Unicorn
    # The monitor process is the main process we interact with
    # @return [Integer]
    def launcher_pid
      master_pid
    end

    # @return [Integer]
    def master_pid
      `ps aux | grep "pitchfork monitor" | grep -v "grep" | awk '{print $2}'`.strip.to_i
    end

    # @param master_pid [Integer]
    # @return [Array<Integer>]
    def workers(master_pid)
      # Workers are children of the monitor process in Pitchfork
      `ps -f --ppid #{master_pid} | grep worker | awk '{ print $2 }'`.split("\n").map(&:to_i)
    end

    # Reload Pitchfork by sending USR2 to monitor, which triggers reforking
    # In Pitchfork, USR2 promotes a worker to a new mold and gradually replaces workers
    # @param launcher_pid [Integer]
    # @param original_master_pid [Integer]
    # @param logger [#call]
    def reload(launcher_pid, original_master_pid, logger)
      logger.call("Triggering #{server_name} refork via monitor pid: #{launcher_pid}")
      Process.kill("USR2", launcher_pid)

      # Pitchfork's reforking is gradual - workers are replaced one by one
      # Wait for the process to complete by checking the generation of workers
      logger.call("Waiting for #{server_name} to complete reforking")

      # Give it some time to start the refork process
      sleep 5

      # Wait for workers to be ready by checking the health endpoint
      iterations = 0
      while `curl -s #{local_web_url}` != "ok"
        iterations += 1
        break if iterations >= 60
        logger.call("Waiting for #{server_name} workers to be ready#{"." * iterations}")
        sleep 2
      end

      # Additional wait to ensure all workers have been reforked
      # This is a simplified approach - in production you might want to check worker generations
      logger.call("Allowing time for #{server_name} to complete worker rollout")
      sleep 10
    end

    # Pitchfork may not support pausing sidekiq via TSTP signal
    # Sidekiq is managed through service workers in the config
    # @param master_pid [Integer]
    # @return [Boolean]
    def pause_sidekiq(master_pid)
      # Pitchfork doesn't support TSTP/CONT for sidekiq control
      # Sidekiq management is handled differently through service workers
      false
    end

    # @param master_pid [Integer]
    # @return [Boolean]
    def resume_sidekiq(master_pid)
      false
    end

    # @return [Integer]
    def min_workers
      1
    end
  end
end
