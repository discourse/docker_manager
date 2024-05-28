# frozen_string_literal: true

# This is the compatibility parser introduced in https://github.com/discourse/discourse/pull/22714
# It's copied here to be used as a fallback when docker_manager is running on an older Discourse version.
# Should be removed just before the Discourse 3.2 release.
module DockerManager::FallbackCompatibilityParser
  def self.find_compatible_resource(version_list, target_version = ::Discourse::VERSION::STRING)
    return if version_list.blank?

    begin
      version_list = YAML.safe_load(version_list)
    rescue Psych::SyntaxError, Psych::DisallowedClass => e
    end

    raise Discourse::InvalidVersionListError unless version_list.is_a?(Hash)

    version_list =
      version_list
        .transform_keys do |v|
          Gem::Requirement.parse(v)
        rescue Gem::Requirement::BadRequirementError => e
          raise Discourse::InvalidVersionListError, "Invalid version specifier: #{v}"
        end
        .sort_by do |parsed_requirement, _|
          operator, version = parsed_requirement
          [version, operator == "<" ? 0 : 1]
        end

    parsed_target_version = Gem::Version.new(target_version)

    lowest_matching_entry =
      version_list.find do |parsed_requirement, target|
        req_operator, req_version = parsed_requirement
        req_operator = "<=" if req_operator == "="

        if !%w[<= <].include?(req_operator)
          raise Discourse::InvalidVersionListError,
                "Invalid version specifier operator for '#{req_operator} #{req_version}'. Operator must be one of <= or <"
        end

        resolved_requirement = Gem::Requirement.new("#{req_operator} #{req_version}")
        resolved_requirement.satisfied_by?(parsed_target_version)
      end

    return if lowest_matching_entry.nil?

    checkout_version = lowest_matching_entry[1]

    begin
      Discourse::Utils.execute_command "git",
                                       "check-ref-format",
                                       "--allow-onelevel",
                                       checkout_version
    rescue RuntimeError
      raise Discourse::InvalidVersionListError, "Invalid ref name: #{checkout_version}"
    end

    checkout_version
  end

  # Find a compatible resource from a git repo
  def self.find_compatible_git_resource(path)
    return unless File.directory?("#{path}/.git")
    compat_resource, std_error, s =
      Open3.capture3(
        "git -C '#{path}' show HEAD@{upstream}:#{Discourse::VERSION_COMPATIBILITY_FILENAME}",
      )
    self.find_compatible_resource(compat_resource) if s.success?
  rescue Discourse::InvalidVersionListError => e
    $stderr.puts "Invalid version list in #{path}"
  end
end
