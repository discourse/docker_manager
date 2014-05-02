# like Grit just very very minimal
class DockerManager::GitRepo
  attr_reader :path, :name

  def initialize(path, name=nil)
    @path = path
    @name = name
    @memoize = {}
  end

  def start_upgrading
    $redis.setnx(upgrade_key, 1)
  end

  def stop_upgrading
    $redis.del(upgrade_key)
  end

  def upgrading?
    $redis.get(upgrade_key).present?
  end

  def valid?
    File.directory?("#{path}/.git")
  end

  def latest_local_commit
    run "rev-parse --short HEAD"
  end

  def latest_origin_commit
    run "rev-parse --short #{tracking_branch}"
  end

  def latest_origin_commit_date
    commit_date(latest_origin_commit)
  end

  def latest_local_commit_date
    commit_date(latest_local_commit)
  end

  def commits_behind
    run("rev-list --count HEAD..#{tracking_branch}").to_i
  end

  def url
    url = run "config --get remote.origin.url"
    if url =~ /^git/
      # hack so it works with git urls
      url = "https://github.com/#{url.split(":")[1]}"
    end

    url
  end

  def update!
    `cd #{path} && git remote update`
  end

  protected

  def upgrade_key
    @upgrade_key ||= "upgrade:#{path}"
  end

  def commit_date(commit)
    unix_timestamp = run('show -s --format="%ct" ' << commit).to_i
    Time.at(unix_timestamp).to_datetime
  end

  def tracking_branch
    run "for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD)"
  end

  def run(cmd)
    @memoize[cmd] ||= `cd #{path} && git #{cmd}`.strip
  rescue => e
    p e
  end

end
