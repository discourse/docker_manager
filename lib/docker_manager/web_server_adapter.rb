# frozen_string_literal: true

module DockerManager
  class WebServerAdapter
    RESTART_FLAG_KEY = "docker_manager:upgrade:server_restarting"

    attr_reader :upgrader

    delegate :log, to: :upgrader

    def initialize(upgrader)
      @upgrader = upgrader
    end

    def workers
      `pgrep -f -P #{master_pid} worker`.split("\n").map(&:to_i)
    end

    def local_web_url
      "http://127.0.0.1:#{ENV["UNICORN_PORT"] || 3000}/srv/status"
    end

    def scale_down_workers(count)
      count.times { Process.kill("TTOU", master_pid) }
    end

    def scale_up_workers(count)
      count.times { Process.kill("TTIN", master_pid) }
    end

    def min_workers
      1
    end

    def reload
      set_restart_flag
      log("Restarting #{server_name} pid: #{launcher_pid}")
      original_master_pid = master_pid
      Process.kill("USR2", launcher_pid)

      # Wait for the original master/monitor to exit (it will spawn a new one)
      iterations = 0
      while pid_exists?(original_master_pid)
        iterations += 1
        break if iterations >= 60
        log("Waiting for #{server_name} to reload#{"." * iterations}")
        sleep 2
      end

      # Wait for workers to be ready
      iterations = 0
      while `curl -s #{local_web_url}` != "ok"
        iterations += 1
        break if iterations >= 60
        log("Waiting for #{server_name} workers to start up#{"." * iterations}")
        sleep 2
      end
      clear_restart_flag
    end

    def set_restart_flag
      Discourse.redis.setex(RESTART_FLAG_KEY, 2.minutes.to_i, 1)
    end

    def clear_restart_flag
      Discourse.redis.del(RESTART_FLAG_KEY)
    end

    private

    def pid_exists?(pid)
      Process.getpgid(pid)
    rescue Errno::ESRCH
      false
    end
  end
end
