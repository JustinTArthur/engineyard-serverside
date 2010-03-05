module EY
  class Deploy::Configuration
    DEFAULT_CONFIG = {
      "migrate"      => "rake db:migrate",
      "branch"       => "master",
      "copy_exclude" => ".git",
      "strategy"     => "Git",
    }

    attr_reader :configuration

    def initialize(opts={})
      @configuration = DEFAULT_CONFIG.merge(opts)
    end

    # Delegate to the configuration objects
    def method_missing(meth, *args, &blk)
      if configuration.key?(meth.to_s)
        configuration[meth.to_s]
      else
        super
      end
    end

    def respond_to?(meth)
      if configuration.key?(meth.to_s)
        true
      else
        super
      end
    end

    def repository_cache
      configuration['repository_cache'] || File.join(deploy_to, "/shared/cached-copy")
    end

    def repo
      configuration['repo'] || EY.node["applications"][app]["repository_name"]
    end

    def deploy_to
      configuration['deploy_to'] || "/data/#{app}"
    end

    def migrate?
      !!configuration['migrate']
    end

    def migration_command
      configuration['migrate']
    end

    def user
      EY.node['users'].first['username'] || 'nobody'
    end
    alias :group :user

    def role
      EY.node['instance_role']
    end

    def copy_exclude
      @copy_exclude ||= Array(configuration.fetch("copy_exclude", []))
    end

    def stack
      EY.node['environment']['stack']
    end

    def environment
      EY.node['environment']['framework_env']
    end

    def latest_release
      all_releases.last
    end

    def previous_release(current=latest_release)
      index = all_releases.index(current)
      all_releases[index-1]
    end

    def oldest_release
      all_releases.first
    end

    def all_releases
      Dir.glob("#{release_dir}/*").sort
    end

    def framework_envs
      "RAILS_ENV=#{environment} RACK_ENV=#{environment} MERB_ENV=#{environment}"
    end

    def current_path
      File.join(deploy_to, "current")
    end

    def shared_path
      File.join(deploy_to, "shared")
    end

    def release_dir
      File.join(deploy_to, "releases")
    end

    def release_path
      @release_path ||= File.join(release_dir, Time.now.utc.strftime("%Y%m%d%H%M%S"))
    end

    def exclusions
      copy_exclude.map { |e| %|--exclude="#{e}"| }.join(' ')
    end

  end
end
