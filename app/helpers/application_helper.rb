require 'open3'

module DockerManager::ApplicationHelper
  def has_latest_pngcrush
    cmd = 'pngcrush -version'
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      pngcrush_version = stderr.read.strip.split(/\s+/)[1][0...-1]
      @has_latest_pngcrush ||= Gem::Version.new(pngcrush_version) >= Gem::Version.new('1.7.85')
    end
  end

  def discourse_root_url
    Discourse.base_uri
  end

  def long_polling_base_url
    SiteSetting.long_polling_base_url
  end
end
