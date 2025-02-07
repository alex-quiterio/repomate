# lib/repomate/manager.rb
module Repomate
  class Manager
    def initialize(config)
      @config = config
    end

    def run
      case @config.command
      when 'sync'
        sync_all_repos
      when 'add'
        add_repo
      when 'remove'
        remove_repo
      when 'list'
        list_repos
      else
        puts "Unknown command: #{@config.command}"
        exit 1
      end
    end

    private

    def update_repo(url)
      repo_name = url.split('/').last.gsub('.git', '')
      repo_path = "#{@config.code_path}/#{repo_name}"

      if Dir.exist?(repo_path)
        update_existing_repo(repo_path, repo_name)
      else
        clone_new_repo(url, repo_path, repo_name)
      end
    end

    def sync_all_repos
      if File.zero?(@config.config_file_path)
        puts "No repositories configured. Add some with 'add' command."
        return
      end

      File.readlines(@config.config_file_path).each do |line|
        url = line.strip
        next if url.empty?
        update_repo(url)
      end
    end

    def add_repo
      unless @config.repo_url
        puts "Error: Repository URL is required"
        exit 1
      end

      repos = File.exist?(@config.config_file_path) ? File.readlines(@config.config_file_path).map(&:strip) : []

      if repos.include?(@config.repo_url)
        puts "Repository already in sync list"
        return
      end

      File.open(@config.config_file_path, 'a') do |file|
        file.puts @config.repo_url
      end
      puts "Added #{@config.repo_url} to sync list"
    end

    def remove_repo
      unless @config.repo_url
        puts "Error: Repository URL is required"
        exit 1
      end

      repos = File.exist?(@config.config_file_path) ? File.readlines(@config.config_file_path).map(&:strip) : []

      unless repos.include?(@config.repo_url)
        puts "Repository not found in sync list"
        return
      end

      repos.delete(@config.repo_url)
      File.write(@config.config_file_path, repos.join("\n") + "\n")
      puts "Removed #{@config.repo_url} from sync list"
    end

    def list_repos
      if File.zero?(@config.config_file_path)
        puts "No repositories configured. Add some with 'add' command."
        return
      end

      puts "Repositories in sync list:"
      File.readlines(@config.config_file_path).each do |line|
        url = line.strip
        next if url.empty?
        puts "- #{url}"
      end
    end

    def update_existing_repo(repo_path, repo_name)
      Dir.chdir(repo_path) do
        puts "Pulling latest changes for #{repo_name}..."
        system("git checkout main && git pull")
      end
    end

    def clone_new_repo(url, repo_path, repo_name)
      puts "Cloning repository #{repo_name} into #{repo_path}..."
      system("git clone #{url} #{repo_path}")
    end
  end
end
