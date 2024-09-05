# frozen_string_literal: true

module GitHelpers
  CLONE_FULL = :full
  CLONE_SHALLOW = :shallow
  CLONE_TREELESS = :treeless

  class RemoteGitRepo
    attr_reader :url, :root_path, :work_path, :remote_path

    @@caches = {}

    def initialize(initial_branch: "main", cache_key: nil, force: false, &blk)
      @initial_branch = initial_branch
      @local_clone_count = 0
      @root_path = Dir.mktmpdir
      @remote_path = File.join(@root_path, "remote.git")
      @work_path = File.join(@root_path, "work")
      @url = "file://#{@remote_path}"

      if !force
        @@caches[cache_key] ||= self.class.new(initial_branch:, cache_key:, force: true, &blk)
        FileUtils.cp_r(@@caches[cache_key].root_path + "/.", @root_path)
        Dir.chdir(@work_path) { git "remote remove origin && git remote add origin #{@url}" }
        return
      end

      Dir.mkdir(@remote_path)
      Dir.chdir(@remote_path) do
        git "init --bare --initial-branch=#{initial_branch}"
        git "config core.sharedrepository 1"
        git "config receive.denyNonFastforwards true"
        git "config receive.denyCurrentBranch ignore"
        git "config uploadpack.allowFilter true"
        git "config commit.gpgsign false"
      end

      Dir.mkdir(@work_path)
      Dir.chdir(@work_path) do
        git "init . --initial-branch=#{initial_branch}"
        git "config commit.gpgsign false"
        git "remote add origin #{@url}"

        File.write("README.md", "This is a git repo for testing docker_manager.")
        File.write("version.txt", "")

        git "add ."
        git "commit -m 'Initial commit'"
        git "push --set-upstream origin #{initial_branch}"
      end

      yield(self) if block_given?
    end

    def destroy
      FileUtils.rm_rf(@root_path)
    end

    def create_local_clone(method:)
      path = File.join(@root_path, "local_#{@local_clone_count}")

      Dir.mkdir(path)
      Dir.chdir(path) do
        case (method)
        when CLONE_FULL
          git "clone #{@url} ."
        when CLONE_SHALLOW
          git "clone --depth 1 #{@url} ."
        when CLONE_TREELESS
          git "clone --filter=tree:0 #{@url} ."
        end

        yield(method(:git)) if block_given?
      end

      @local_clone_count += 1
      LocalGitRepo.new(path, method)
    end

    def in_working_directory
      Dir.chdir(@work_path) { yield(method(:git)) }
    end

    def in_remote_repo
      Dir.chdir(@remote_path) { yield(method(:git)) }
    end

    def commit(filename:, commits:, branch: nil)
      branch ||= @initial_branch

      Dir.chdir(@work_path) do
        git "checkout #{branch}"

        commits.each do |commit|
          env = commit[:date] ? build_env(date: commit[:date]) : nil
          File.write(filename, commit[:content])

          git "add #{filename}"
          git "commit -m 'Update #{filename} with #{commit[:content].truncate(10)}'", env: env

          if commit[:tags]
            commit[:tags].each do |tag|
              if git("tag -l #{tag}", raise_exception: false)
                git "tag -d #{tag}"
                git "push --delete origin #{tag}"
              end

              git "tag -a #{tag} -m 'Tagging #{tag}'"
            end
          end
        end

        git "push --follow-tags"
      end
    end

    def create_branches(*branch_names)
      Dir.chdir(@work_path) do
        branch_names.each do |branch|
          git "checkout #{@initial_branch}"
          git "checkout -b #{branch}"
          git "push --set-upstream origin #{branch}"
        end
      end
    end

    def delete_branches(*branch_names)
      Dir.chdir(@work_path) do
        branch_names.each do |branch|
          git "checkout #{@initial_branch}"
          git "branch -d #{branch}"
          git "push origin --delete #{branch}"
        end
      end
    end

    def rename_branch(old_name:, new_name:)
      Dir.chdir(@work_path) do
        git "checkout #{old_name}"
        git "branch -m #{new_name}"
        git "push origin -u #{new_name}"

        if old_name == @initial_branch
          Dir.chdir(@remote_path) { git "symbolic-ref HEAD refs/heads/#{new_name}" }
        end

        git "push origin --delete #{old_name}"
      end
    end

    def rebase(source_branch:, target_branch:)
      Dir.chdir(@work_path) do
        git "checkout #{target_branch}"
        git "rebase #{source_branch}"
        git "push --force"
      end
    end

    def delete_tags(*tag_names)
      Dir.chdir(@work_path) do
        tag_names.each do |tag|
          git "tag -d #{tag}"
          git "push --delete origin #{tag}"
        end
      end
    end

    private

    def git(command, env: "", raise_exception: true)
      env = build_env if command.start_with?("commit") && env.blank?
      stdout, stderr, status = Open3.capture3("#{env} git #{command}".strip)

      if status.success? || !raise_exception
        stdout.presence
      else
        raise RuntimeError.new("stderr while running #{command}: #{stderr}")
      end
    end

    def build_env(name: "Alice", email: "alice@example.com", date: "2023-03-06T20:27:03Z")
      "GIT_AUTHOR_NAME='#{name}' GIT_AUTHOR_EMAIL='#{email}' GIT_AUTHOR_DATE='#{date}' " \
        "GIT_COMMITTER_NAME='#{name}' GIT_COMMITTER_EMAIL='#{email}' GIT_COMMITTER_DATE='#{date}'"
    end
  end

  class LocalGitRepo
    attr_reader :path

    def initialize(path, clone_method)
      @path = path
      @clone_method = clone_method
    end

    def git(*commands)
      Dir.chdir(@path) do
        commands.map do |command|
          stdout, stderr, status = Open3.capture3("git #{command}".strip)
          status.success? ? stdout : (raise RuntimeError)
        end
      end
    end

    def commit_count
      git("rev-list --all --count").first.to_i
    end

    def checkout(ref)
      if @clone_method == CLONE_SHALLOW
        git "remote set-branches origin #{ref}"
        git "fetch --depth 1 origin #{ref}"
      else
        git "fetch origin #{ref}"
      end

      git "-c advice.detachedHead=false checkout #{ref}"
    end
  end
end
