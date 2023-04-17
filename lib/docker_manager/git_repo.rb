# frozen_string_literal: true

class DockerManager::GitRepo
  attr_reader :path, :name

  def self.find_all
    repos = [
      DockerManager::GitRepo.new(Rails.root.to_s, "discourse"),
      DockerManager::GitRepo.new("#{Rails.root}/plugins/docker_manager", "docker_manager"),
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

  def initialize(path, name = nil)
    @path = path
    @name = name
    @memoize = {}
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
    run "rev-parse #{tracking_ref}^{}"
  end

  def latest_local_tag_version
    prettify_tag_version("describe --exclude 'beta' HEAD 2>/dev/null")
  end

  def latest_origin_tag_version
    prettify_tag_version(
      "describe --exclude 'beta' --exclude 'latest-release' #{tracking_ref} 2>/dev/null",
    )
  end

  def latest_local_commit_date
    commit_date(latest_local_commit)
  end

  def latest_origin_commit_date
    commit_date(latest_origin_commit)
  end

  def commits_behind
    run("rev-list --count HEAD..#{tracking_ref}").to_i
  end

  def url
    url = run("config --get remote.origin.url")
    url = "https://github.com/#{url}" if url&.delete_prefix!("git@github.com:")
    url
  end

  def update_remote!
    if shallow_clone?
      run("fetch --depth=1 origin")
    else
      run("fetch --tags --prune --prune-tags --force origin")
    end
  end

  def has_local_main?
    run("show-ref refs/heads/main").present?
  end

  def tracking_ref
    tracking_branch.presence || tracking_tag
  end

  def upstream_branch
    head_ref = run("symbolic-ref -q HEAD")
    return if head_ref.blank?
    run("for-each-ref --format='%(upstream:short)' #{head_ref}")
  end

  def upstream_branch_exist?
    origin_branch_exist?(upstream_branch)
  end

  protected

  def shallow_clone?
    run("rev-parse --is-shallow-repository") == "true"
  end

  def prettify_tag_version(command)
    result = run(command)
    return if result.blank?

    result = result.gsub(/-(\d+)-.*/, " +#{$1}") if result =~ /-(\d+)-/
    result
  end

  def upgrade_key
    @upgrade_key ||= "upgrade:#{path}"
  end

  def commit_date(commit)
    return nil if commit.blank?
    unix_timestamp = run("show -s --format='%ct' #{commit}").to_i
    Time.at(unix_timestamp).to_datetime
  end

  def origin_branch_exist?(branch_name)
    return false if branch_name.blank?

    if shallow_clone?
      branch_name = branch_name.delete_prefix("origin/")
      run("ls-remote --heads origin #{branch_name}").present?
    else
      (run("show-branch remotes/#{branch_name}") || "").include?(branch_name)
    end
  end

  def tracking_branch
    branch = Discourse.find_compatible_git_resource(path)
    return branch if branch.present?

    head = upstream_branch

    # We prefer `origin/main` to `origin/master`
    if head == "origin/master"
      main_branch = "origin/main"
      return main_branch if origin_branch_exist?(main_branch)
    end

    head
  end

  def tracking_tag
    run("config user.discourse-version")
  end

  def run(cmd)
    @memoize[cmd] ||= begin
      output, status = Open3.capture2("git #{cmd}", chdir: path)
      status == 0 ? output.strip : nil
    end
  rescue => e
    puts e.inspect
  end
end
