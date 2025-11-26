# frozen_string_literal: true

module DockerManager
  # Base adapter class for web server process management
  # Provides an interface for interacting with Unicorn or Pitchfork servers
  class WebServerAdapter
    # @return [String] the local web server URL for health checks
    def local_web_url
      "http://127.0.0.1:#{ENV["UNICORN_PORT"] || 3000}/srv/status"
    end

    # Scale down workers by sending TTOU signals
    # @param master_pid [Integer] the master/monitor PID
    # @param count [Integer] number of workers to scale down
    def scale_down_workers(count)
      count.times { Process.kill("TTOU", master_pid) }
    end

    # Scale up workers by sending TTIN signals
    # @param master_pid [Integer] the master/monitor PID
    # @param count [Integer] number of workers to scale up
    def scale_up_workers(count)
      count.times { Process.kill("TTIN", master_pid) }
    end

    # Pause sidekiq workers if supported
    # @param master_pid [Integer] the master/monitor PID
    # @return [Boolean] true if sidekiq was paused, false if not supported
    def pause_sidekiq
      false
    end

    # Minimum number of workers required for safe upgrade
    # @return [Integer]
    def min_workers
      1
    end

    private

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
