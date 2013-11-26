class DockerManager::Upgrader
  attr_accessor :user_id, :path

  def self.upgrade(user_id, path)
    self.new(user_id: user_id, path: path).upgrade
  end

  def initialize(opts)
    self.user_id = opts[:user_id]
    self.path= opts[:path]
  end

  def upgrade
    run("cd #{path} && git pull")
    run("bundle install --deployment --without test --without development")
    run("bundle exec rake db:migrate")
    run("bundle exec rake assets:precompile")
    sidekiq_pid = `ps aux | grep sidekiq.*busy | grep -v grep | awk '{ print $2 }'`.strip.to_i
    if sidekiq_pid > 0
      Process.kill("TERM", sidekiq_pid)
      log("Killed sidekiq")
    else
      log("Warning: Sidekiq was not found")
    end
    pid = `ps aux  | grep unicorn_launcher | grep -v sudo | grep -v grep | awk '{ print $2 }'`.strip
    if pid.to_i > 0
      log("Restarting unicorn pid: #{pid}")
      Process.kill("USR2", pid.to_i)
      log("DONE")
    else
      log("Did not find unicorn launcher")
    end
  rescue
    STDERR.puts("Docker Manager: FAILED TO UPGRADE")
    raise
  end

  def run(cmd)
    log "$ #{cmd}"
    IO.popen("cd #{Rails.root} && #{cmd} 2>&1") do |line|
      log(line.read)
    end

    unless $?.success?
      STDERR.puts("FAILED: #{cmd}")
      raise RuntimeError
    end
  end

  def log(message)
    MessageBus.publish("/docker/log", message, user_ids: [user_id])
  end
end
