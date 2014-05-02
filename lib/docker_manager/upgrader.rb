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

  def upgrade
    return unless @repo.start_upgrading

    clear_logs

    # HEAD@{upstream} is just a fancy way how to say origin/master (in normal case)
    # see http://stackoverflow.com/a/12699604/84283
    run("cd #{@repo.path} && git fetch && git reset --hard HEAD@{upstream}")
    log("********************************************************")
    log("*** Please be patient, next steps might take a while ***")
    log("********************************************************")
    run("bundle install --deployment --without test --without development")
    percent(25)
    run("bundle exec rake multisite:migrate")
    percent(50)
    log("***  Bundling assets. This might take a while *** ")
    run("bundle exec rake assets:precompile")
    percent(75)
    sidekiq_pid = `ps aux | grep sidekiq.*busy | grep -v grep | awk '{ print $2 }'`.strip.to_i
    if sidekiq_pid > 0
      Process.kill("TERM", sidekiq_pid)
      log("Killed sidekiq")
    else
      log("Warning: Sidekiq was not found")
    end
    percent(100)
    publish('status', 'complete')
    pid = `ps aux  | grep unicorn_launcher | grep -v sudo | grep -v grep | awk '{ print $2 }'`.strip
    if pid.to_i > 0
      log("***********************************************")
      log("*** After restart, upgrade will be complete ***")
      log("***********************************************")
      log("Restarting unicorn pid: #{pid}")
      Process.kill("USR2", pid.to_i)
      log("DONE")
    else
      log("Did not find unicorn launcher")
    end
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

    IO.popen(clear_env, "cd #{Rails.root} && #{cmd} 2>&1") do |line|
      line = line.read
      log(line)
      msg << line << "\n"
    end

    unless $?.success?
      STDERR.puts("FAILED: #{cmd}")
      STDERR.msg(msg)
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
end
