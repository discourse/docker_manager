# frozen_string_literal: true

class DockerManager::BaseImage
  REPO_URL = "https://github.com/discourse/discourse_docker.git"
  TEMPLATE_PATH = "templates/web.template.yml"
  VERSION_FILE = "/VERSION"
  GIT_TIMEOUT = 10

  def self.outdated?
    return true if !File.exist?(VERSION_FILE)
    Gem::Version.new(File.read(VERSION_FILE)) < expected_version
  end

  def self.expected_version
    Dir.mktmpdir do |dir|
      git(dir, "init", "--quiet", "--bare")
      git(dir, "fetch", "--quiet", "--depth=1", REPO_URL, "main")
      template = YAML.safe_load(git(dir, "show", "FETCH_HEAD:#{TEMPLATE_PATH}"))
      Gem::Version.new(template.fetch("base_image").split(":").last)
    end
  end

  def self.git(dir, *args)
    Discourse::Utils.execute_command("git", *args, chdir: dir, timeout: GIT_TIMEOUT)
  end
  private_class_method :git
end
