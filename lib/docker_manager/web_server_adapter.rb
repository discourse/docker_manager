# frozen_string_literal: true

module DockerManager
  # Base adapter class for web server process management
  # Provides an interface for interacting with Unicorn or Pitchfork servers
  class WebServerAdapter
    # @return [String] the name of the web server
    def server_name
      raise NotImplementedError
    end

    # @return [Integer] the PID of the launcher/supervisor process (0 if not found)
    def launcher_pid
      raise NotImplementedError
    end

    # @return [Integer] the PID of the master/monitor process (0 if not found)
    def master_pid
      raise NotImplementedError
    end

    # @param master_pid [Integer] the master/monitor process PID
    # @return [Array<Integer>] array of worker PIDs
    def workers(master_pid)
      raise NotImplementedError
    end

    # @return [String] the local web server URL for health checks
    def local_web_url
      "http://127.0.0.1:#{ENV["UNICORN_PORT"] || 3000}/srv/status"
    end

    # Reload the web server
    # @param launcher_pid [Integer] the launcher/supervisor PID to signal
    # @param master_pid [Integer] the current master/monitor PID
    # @param logger [#call] a proc/lambda for logging messages
    def reload(launcher_pid, master_pid, logger)
      raise NotImplementedError
    end

    # Scale down workers by sending TTOU signals
    # @param master_pid [Integer] the master/monitor PID
    # @param count [Integer] number of workers to scale down
    def scale_down_workers(master_pid, count)
      count.times { Process.kill("TTOU", master_pid) }
    end

    # Scale up workers by sending TTIN signals
    # @param master_pid [Integer] the master/monitor PID
    # @param count [Integer] number of workers to scale up
    def scale_up_workers(master_pid, count)
      count.times { Process.kill("TTIN", master_pid) }
    end

    # Pause sidekiq workers if supported
    # @param master_pid [Integer] the master/monitor PID
    # @return [Boolean] true if sidekiq was paused, false if not supported
    def pause_sidekiq(master_pid)
      false
    end

    # Resume sidekiq workers if supported
    # @param master_pid [Integer] the master/monitor PID
    # @return [Boolean] true if sidekiq was resumed, false if not supported
    def resume_sidekiq(master_pid)
      false
    end

    # Minimum number of workers required for safe upgrade
    # @return [Integer]
    def min_workers
      1
    end

    protected

    # Check if a PID exists
    # @param pid [Integer]
    # @return [Boolean]
    def pid_exists?(pid)
      Process.getpgid(pid)
    rescue Errno::ESRCH
      false
    end
  end
end
