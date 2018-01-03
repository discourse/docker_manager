class DockerManager::Upgrader

  def initialize(user_id, repo, from_version)
    @user_id = user_id
    @repo = repo
    @from_version = from_version
  end

  def reset!
    @repo.stop_upgrading
    clear_logs
    percent(0)
  end

  def num_unicorn_workers
    `ps aux | grep "unicorn worker\\[" | wc -l`.strip.to_i
  end

  def unicorn_master_pid
    `ps aux | grep "unicorn master -E" | grep -v "grep" | awk '{print $2}'`.strip.to_i
  end

  def min_workers
    2
  end

  def unicorn_launcher_pid
    `ps aux  | grep unicorn_launcher | grep -v sudo | grep -v grep | awk '{ print $2 }'`.strip.to_i
  end

  def try(times, cond)
    while cond.call && times > 0
      times -= 1
      yield
    end
  end

  def upgrade
    return unless @repo.start_upgrading

    percent(0)

    clear_logs

    log("********************************************************")
    log("*** Please be patient, next steps might take a while ***")
    log("********************************************************")

    launcher_pid = unicorn_launcher_pid

    master_pid = unicorn_master_pid
    workers = num_unicorn_workers

    if workers < 2
      log("ABORTING, you do not have enough unicorn workers running")
      raise "Not enough workers"
    end

    if launcher_pid <= 0 || master_pid <= 0
      log("ABORTING, missing unicorn launcher or unicorn master")
      raise "No unicorn master or launcher"
    end

    # log("Cycling web, to free up memory")
    # Process.kill("USR2", launcher_pid.to_i)
    #
    # sleep 10
    #
    # percent(10)
    #
    # try(20, -> {master_pid == unicorn_master_pid}) do
    #   sleep 1
    # end
    #
    # try(20, -> {num_unicorn_workers < 2}) do
    #   sleep 1
    # end
    #
    # master_pid = unicorn_master_pid
    # workers = num_unicorn_workers
    # log "New master pid is #{master_pid}"
    #
    # percent(15)
    #
    # # wince down so we only have 2 workers
    # if workers > min_workers
    #   log "Stopping #{workers-min_workers} web workers, to free up memory"
    #   (workers - min_workers).times do
    #     Process.kill("TTOU", master_pid)
    #   end
    # end
    #
    #
    if ENV["UNICORN_SIDEKIQS"].to_i > 0
      log "Stopping job queue to reclaim memory, master pid is #{master_pid}"
      Process.kill("TSTP", master_pid)
      sleep 1
      # older versions do not have support, so quickly send a cont so master process is not hung
      Process.kill("CONT", master_pid)
    end

    # HEAD@{upstream} is just a fancy way how to say origin/master (in normal case)
    # see http://stackoverflow.com/a/12699604/84283
    run("cd #{@repo.path} && git fetch --tags && git reset --hard HEAD@{upstream}")
    percent(20)
    run("bundle install --deployment --without test --without development")
    percent(30)
    run("bundle exec rake multisite:migrate")
    percent(40)
    log("***  Bundling assets. This will take a while *** ")
    less_memory_flags = "RUBY_GC_MALLOC_LIMIT_MAX=20971520 RUBY_GC_OLDMALLOC_LIMIT_MAX=20971520 RUBY_GC_HEAP_GROWTH_MAX_SLOTS=50000 RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=0.9 "
    run("#{less_memory_flags} bundle exec rake assets:precompile")

    percent(100)
    publish('status', 'complete')
    log_version_upgrade

    log("***********************************************")
    log("*** After restart, upgrade will be complete ***")
    log("***********************************************")
    log("Restarting unicorn pid: #{launcher_pid}")
    Process.kill("USR2", launcher_pid)
    log("DONE")

  rescue => ex
    publish('status', 'failed')
    STDERR.puts("Docker Manager: FAILED TO UPGRADE")
    STDERR.puts(ex.inspect)
    raise
  ensure
    @repo.stop_upgrading
  end

  def publish(type, value)
    MessageBus.publish("/docker/upgrade", {type: type, value: value}, user_ids: [@user_id])
  end

  def run(cmd)
    log "$ #{cmd}"
    msg = ""

    clear_env = Hash[*ENV.map{|k,v| [k,nil]}
                     .reject{ |k,v|
                       ["PWD","HOME","SHELL","PATH"].include?(k) ||
                         k =~ /^DISCOURSE_/
                     }
                     .flatten]
    clear_env["RAILS_ENV"] = "production"
    clear_env["TERM"] = 'dumb' # claim we have a terminal

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
    "logs:#{@repo.path}:#{@from_version}"
  end

  def clear_logs
    $redis.del(logs_key)
  end

  def find_logs
    $redis.get(logs_key)
  end

  def percent_key
    "percent:#{@repo.path}:#{@from_version}"
  end

  def last_percentage
    $redis.get(percent_key)
  end

  def percent(val)
    $redis.set(percent_key, val)
    $redis.expire(percent_key, 30.minutes)
    publish('percent', val)
  end

  def log(message)
    $redis.append logs_key, message + "\n"
    $redis.expire(logs_key, 30.minutes)
    publish 'log', message
  end

  def log_version_upgrade
    StaffActionLogger.new(User.find(@user_id)).log_custom('discourse_upgrade', from_version: @from_version, repository: @repo.path)
  end
end
