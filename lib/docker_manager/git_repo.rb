# frozen_string_literal: true

# like Grit just very very minimal
class DockerManager::GitRepo
  attr_reader :path, :name, :branch

  def initialize(path, name = nil)
    @path = path
    @name = name
    @memoize = {}
    @branch = tracking_branch
  end

  def start_upgrading
    Discourse.redis.setnx(upgrade_key, latest_local_commit)
  end

  def stop_upgrading
    Discourse.redis.del(upgrade_key)
  end

  def upgrade_version
    @upgrade_version ||= Discourse.redis.get(upgrade_key)
  end

  def upgrading?
    upgrade_version.present?
  end

  def valid?
    File.exist?("#{path}/.git")
  end

  def latest_local_commit
    run "rev-parse HEAD"
  end

  def latest_origin_commit
    run "rev-parse #{tracking_branch}"
  end

  def latest_local_tag_version
    prettify_tag_version("describe HEAD 2>/dev/null")
  end

  def latest_origin_tag_version
    prettify_tag_version("describe #{tracking_branch} 2>/dev/null")
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

  def update_remote!
    `cd #{path} && git remote update`
  end

  def self.find_all
    repos = [
      DockerManager::GitRepo.new(Rails.root.to_s, "discourse"),
      DockerManager::GitRepo.new(
        "#{Rails.root}/plugins/docker_manager",
        "docker_manager"
      )
    ]

    Discourse.visible_plugins.each do |p|
      next if p.name == "docker_manager"
      repo = DockerManager::GitRepo.new(File.dirname(p.path), p.name)
      repos << repo if repo.valid?
    end

    repos
  end

  def self.find(path)
    find_all.detect { |r| r.path == path }
  end

  def upstream_branch
    @upstream_branch ||=
      run(
        "for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD)"
      )
  end

  def has_local_main?
    run("show-ref refs/heads/main").present?
  end

  protected

  def prettify_tag_version(command)
    result = run(command)
    return unless result.present?

    result = result.gsub(/-(\d+)-.*/, " +#{$1}") if result =~ /-(\d+)-/
    result
  end

  def upgrade_key
    @upgrade_key ||= "upgrade:#{path}"
  end

  def commit_date(commit)
    unix_timestamp = run(+'show -s --format="%ct" ' << commit).to_i
    Time.at(unix_timestamp).to_datetime
  end

  def has_origin_main?
    begin
      run("branch -a").match?(%r{remotes/origin/main$})
    rescue StandardError
      false
    end
  end

  def tracking_branch
    branch = Discourse.find_compatible_git_resource(path)
    return branch if branch.present?

    head = upstream_branch

    # We prefer `origin/main` to `origin/master`
    if head == "origin/master"
      return "origin/main" if has_origin_main?
    end

    head
  end

  def run(cmd)
    @memoize[cmd] ||= `cd #{path} && git #{cmd}`.strip
  rescue => e
    p e
  end
end
