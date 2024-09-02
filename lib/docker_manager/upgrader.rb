# frozen_string_literal: true

class DockerManager::Upgrader
  def initialize(user_id, repos, from_version)
    @user_id = user_id
    @repos = repos.is_a?(Array) ? repos : [repos]
    @from_version = from_version
  end

  def reset!
    @repos.each(&:stop_upgrading)
    clear_logs
    percent(0)
    status(nil)
  end

  def min_workers
    1
  end

  def upgrade
    return if @repos.any? { |repo| !repo.start_upgrading }

    percent(0)
    status("running")

    clear_logs

    log("********************************************************")
    log("*** Please be patient, next steps might take a while ***")
    log("********************************************************")

    launcher_pid = unicorn_launcher_pid
    master_pid = unicorn_master_pid
    workers = unicorn_workers(master_pid).size

    if workers < 2
      log("ABORTING, you do not have enough unicorn workers running")
      raise "Not enough workers"
    end

    if launcher_pid <= 0 || master_pid <= 0
      log("ABORTING, missing unicorn launcher or unicorn master")
      raise "No unicorn master or launcher"
    end

    percent(5)

    log("Cycling Unicorn, to free up memory")
    reload_unicorn(launcher_pid)

    percent(10)
    reloaded = false
    num_workers_spun_down = workers - min_workers

    if num_workers_spun_down.positive?
      log "Stopping #{workers - min_workers} Unicorn worker(s), to free up memory"
      num_workers_spun_down.times { Process.kill("TTOU", unicorn_master_pid) }
    end

    if ENV["UNICORN_SIDEKIQS"].to_i > 0
      log "Stopping job queue to reclaim memory, master pid is #{master_pid}"
      Process.kill("TSTP", unicorn_master_pid)
      sleep 1
      # older versions do not have support, so quickly send a cont so master process is not hung
      Process.kill("CONT", unicorn_master_pid)
    end

    # HEAD@{upstream} is just a fancy way how to say origin/main (in normal case)
    # see http://stackoverflow.com/a/12699604/84283
    @repos.each_with_index do |repo, index|
      # We automatically handle renames from `master` -> `main`
      if repo.upstream_branch == "origin/master" && repo.tracking_ref == "origin/main"
        log "Branch has changed to #{repo.tracking_ref}"

        # Just in case `main` exists locally but is not used. Perhaps it was fetched?
        if repo.has_local_main?
          run "cd #{repo.path} && git checkout main"
        else
          run "cd #{repo.path} && git branch -m master main"
        end

        run "cd #{repo.path} && git fetch origin --tags --force"
        run "cd #{repo.path} && git branch -u origin/main main"
        run("cd #{repo.path} && git reset --hard HEAD@{upstream}")
      else
        run("cd #{repo.path} && git fetch --tags --prune-tags --prune --force")

        if repo.detached_head?
          run("cd #{repo.path} && git reset --hard")
          run("cd #{repo.path} && git -c advice.detachedHead=false checkout #{repo.tracking_ref}")
        else
          run("cd #{repo.path} && git reset --hard HEAD@{upstream}")
        end
      end

      percent(20 * (index + 1) / @repos.size)
    end

    run("bundle install --retry 3 --jobs 4")
    run("if [ -f yarn.lock ]; then yarn install; else pnpm install; fi")
    begin
      run("LOAD_PLUGINS=0 bundle exec rake plugin:pull_compatible_all")
    rescue RuntimeError
      log "Unable checkout compatible plugin versions"
    end
    percent(30)
    run("SKIP_POST_DEPLOYMENT_MIGRATIONS=1 bundle exec rake multisite:migrate")
    percent(40)
    log("*** Bundling assets. This will take a while *** ")
    run("bundle exec rake themes:update assets:precompile")

    using_s3_assets =
      ENV["DISCOURSE_USE_S3"] && ENV["DISCOURSE_S3_BUCKET"] && ENV["DISCOURSE_S3_CDN_URL"]

    run("bundle exec rake s3:upload_assets") if using_s3_assets

    percent(80)
    reload_unicorn(launcher_pid)
    reloaded = true

    # Flush nginx cache here - this is not critical, and the rake task may not exist yet - ignore failures here.
    percent(85)
    begin
      run("bundle exec rake assets:flush_sw")
    rescue RuntimeError
      log "WARNING: Unable to flush service worker file"
    end

    percent(90)
    log("Running post deploy migrations")
    run("bundle exec rake multisite:migrate")

    run("bundle exec rake s3:expire_missing_assets") if using_s3_assets

    log_version_upgrade
    percent(100)
    log("DONE")
    status("complete")
  rescue => ex
    status("failed")

    ["Docker Manager: FAILED TO UPGRADE", ex.inspect, ex.backtrace.join("\n")].each do |message|
      STDERR.puts(message)
      log(message)
    end

    if num_workers_spun_down.to_i.positive? && !reloaded
      log "Spinning up #{num_workers_spun_down} Unicorn worker(s) that were stopped initially"
      num_workers_spun_down.times { Process.kill("TTIN", unicorn_master_pid) }
    end

    raise ex
  ensure
    @repos.each(&:stop_upgrading)
  end

  def publish(type, value)
    MessageBus.publish(
      "/docker/update",
      { type: type, value: value, repos: @repos.map(&:name) },
      user_ids: [@user_id],
    )
  end

  def run(cmd)
    log "$ #{cmd}"
    msg = +""

    allowed_env = %w[
      PWD
      HOME
      SHELL
      PATH
      COMPRESS_BROTLI
      FORCE_S3_UPLOADS
      HTTP_PROXY
      HTTPS_PROXY
      NO_PROXY
      http_proxy
      https_proxy
      no_proxy
      EMBER_VERSION
    ]

    clear_env =
      Hash[
        *ENV
          .map { |k, v| [k, nil] }
          .reject { |k, v| allowed_env.include?(k) || k =~ /^DISCOURSE_/ }
          .flatten
      ]

    clear_env["RAILS_ENV"] = "production"
    clear_env["TERM"] = "dumb" # claim we have a terminal

    retval = nil
    Open3.popen2e(clear_env, "cd #{Rails.root} && #{cmd} 2>&1") do |_in, out, wait_thread|
      out.each do |line|
        line.rstrip! # the client adds newlines, so remove the one we're given
        log(line)
        msg << line << "\n"
      end
      retval = wait_thread.value
    end

    unless retval == 0
      STDERR.puts("FAILED: '#{cmd}' exited with a return value of #{retval}")
      STDERR.puts(msg)
      raise RuntimeError
    end
  end

  def logs_key
    "logs:#{@repos.map(&:path).join(", ")}:#{@from_version}"
  end

  def clear_logs
    Discourse.redis.del(logs_key)
  end

  def find_logs
    Discourse.redis.get(logs_key)
  end

  def percent_key
    "percent:#{@repos.map(&:path).join(", ")}:#{@from_version}"
  end

  def last_percentage
    Discourse.redis.get(percent_key)
  end

  def percent(val)
    Discourse.redis.set(percent_key, val)
    Discourse.redis.expire(percent_key, 30.minutes)
    publish("percent", val)
  end

  def log(message)
    Discourse.redis.append(logs_key, message + "\n")
    Discourse.redis.expire(logs_key, 30.minutes)
    publish("log", message)
  end

  def status_key
    "status:#{@repos.map(&:path).join(", ")}:#{@from_version}"
  end

  def last_status
    Discourse.redis.get(status_key)
  end

  def status(val)
    Discourse.redis.set(status_key, val)
    Discourse.redis.expire(status_key, 30.minutes)
    publish("status", val)
  end

  def log_version_upgrade
    StaffActionLogger.new(User.find(@user_id)).log_custom(
      "discourse_update",
      from_version: @from_version,
      repository: @repos.map(&:path).join(", "),
    )
  end

  private

  def pid_exists?(pid)
    Process.getpgid(pid)
  rescue Errno::ESRCH
    false
  end

  def unicorn_launcher_pid
    `ps aux | grep unicorn_launcher | grep -v sudo | grep -v grep | awk '{ print $2 }'`.strip.to_i
  end

  def unicorn_master_pid
    `ps aux | grep "unicorn master -E" | grep -v "grep" | awk '{print $2}'`.strip.to_i
  end

  def unicorn_workers(master_pid)
    `ps -f --ppid #{master_pid} | grep worker | awk '{ print $2 }'`.split("\n").map(&:to_i)
  end

  def local_web_url
    "http://127.0.0.1:#{ENV["UNICORN_PORT"] || 3000}/srv/status"
  end

  def reload_unicorn(launcher_pid)
    log("Restarting unicorn pid: #{launcher_pid}")
    original_master_pid = unicorn_master_pid
    Process.kill("USR2", launcher_pid)

    iterations = 0
    while pid_exists?(original_master_pid)
      iterations += 1
      break if iterations >= 60
      log("Waiting for Unicorn to reload#{"." * iterations}")
      sleep 2
    end

    iterations = 0
    while `curl -s #{local_web_url}` != "ok"
      iterations += 1
      break if iterations >= 60
      log("Waiting for Unicorn workers to start up#{"." * iterations}")
      sleep 2
    end
  end
end
