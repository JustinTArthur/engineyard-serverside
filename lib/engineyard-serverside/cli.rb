require 'thor'

module EY
  class CLI < Thor
    include Dataflow

    def self.start(*)
      super
    rescue RemoteFailure
      exit(1)
    end

    method_option :migrate,         :type     => :string,
                                    :desc     => "Run migrations with this deploy",
                                    :aliases  => ["-m"]

    method_option :branch,          :type     => :string,
                                    :desc     => "Git ref to deploy, defaults to master. May be a branch, a tag, or a SHA",
                                    :aliases  => %w[-b --ref --tag]

    method_option :repo,            :type     => :string,
                                    :desc     => "Remote repo to deploy",
                                    :aliases  => ["-r"]

    method_option :app,             :type     => :string,
                                    :required => true,
                                    :desc     => "Application to deploy",
                                    :aliases  => ["-a"]

    method_option :framework_env,   :type     => :string,
                                    :required => true,
                                    :desc     => "Ruby web framework environment",
                                    :aliases  => ["-e"]

    method_option :config,          :type     => :string,
                                    :desc     => "Additional configuration"

    method_option :stack,           :type     => :string,
                                    :desc     => "Web stack (so we can restart it correctly)"

    method_option :instances,       :type     => :array,
                                    :desc     => "Hostnames of instances to deploy to, e.g. --instances localhost app1 app2"

    method_option :instance_roles,  :type     => :hash,
                                    :desc     => "Roles of instances, keyed on hostname, comma-separated. e.g. instance1:app_master,etc instance2:db,memcached ..."

    method_option :instance_names,  :type     => :hash,
                                    :desc     => "Instance names, keyed on hostname. e.g. instance1:name1 instance2:name2"

    method_option :verbose,         :type     => :boolean,
                                    :default  => false,
                                    :desc     => "Verbose output",
                                    :aliases  => ["-v"]

    desc "deploy", "Deploy code from /data/<app>"
    def deploy(default_task=:deploy)
      assemble_instance_hashes.each do |instance_hash|
        if server = EY::Server.by_hostname(instance_hash[:hostname])
          server.roles = instance_hash[:roles]
          server.name = instance_hash[:name]
        else
          EY::Server.add(instance_hash)
        end
      end

      EY::LoggedOutput.verbose = options[:verbose]
      EY::LoggedOutput.logfile = File.join(ENV['HOME'], "#{options[:app]}-deploy.log")

      invoke :propagate
      EY::Deploy.run(options.merge("default_task" => default_task))
    end

    method_option :app,           :type     => :string,
                                  :required => true,
                                  :desc     => "Which application's hooks to run",
                                  :aliases  => ["-a"]

    method_option :release_path,  :type     => :string,
                                  :desc     => "Value for #release_path in hooks (mostly for internal coordination)",
                                  :aliases  => ["-r"]

    method_option :current_roles, :type     => :array,
                                  :desc     => "Value for #current_roles in hooks"

    method_option :framework_env, :type     => :string,
                                  :required => true,
                                  :desc     => "Ruby web framework environment",
                                  :aliases  => ["-e"]

    method_option :config,        :type     => :string,
                                  :desc     => "Additional configuration"

    method_option :current_name,  :type     => :string,
                                  :desc     => "Value for #current_name in hooks"

    desc "hook [NAME]", "Run a particular deploy hook"
    def hook(hook_name)
      EY::DeployHook.new(options).run(hook_name)
    end

    desc "install_bundler [VERSION]", "Make sure VERSION of bundler is installed (in system ruby)"
    def install_bundler(version)
      egrep_escaped_version = version.gsub(/\./, '\.')
      # the grep "bundler " is so that gems like bundler08 don't get
      # their versions considered too
      #
      # the [,$] is to stop us from looking for e.g. 0.9.2, seeing
      # 0.9.22, and mistakenly thinking 0.9.2 is there
      has_bundler_cmd = "gem list bundler | grep \"bundler \" | egrep -q '#{egrep_escaped_version}[,)]'"

      unless system(has_bundler_cmd)
        system("gem install bundler -q --no-rdoc --no-ri -v '#{version}'")
      end
    end

    desc "propagate", "Propagate the engineyard-serverside gem to the other instances in the cluster. This will install exactly version #{VERSION} and remove other versions if found."
    def propagate
      config          = EY::Deploy::Configuration.new
      gem_filename    = "engineyard-serverside-#{VERSION}.gem"
      local_gem_file  = File.join(Gem.dir, 'cache', gem_filename)
      remote_gem_file = File.join(Dir.tmpdir, gem_filename)
      gem_binary      = File.join(Gem.default_bindir, 'gem')

      EY::Server.config = config

      barrier(*(EY::Server.all.find_all do |server|
        !server.local?            # of course this machine has it
      end.map do |server|
        need_later do
          egrep_escaped_version = VERSION.gsub(/\./, '\.')
          # the [,)] is to stop us from looking for e.g. 0.5.1, seeing
          # 0.5.11, and mistakenly thinking 0.5.1 is there
          has_gem_cmd = "#{gem_binary} list engineyard-serverside | grep \"engineyard-serverside\" | egrep -q '#{egrep_escaped_version}[,)]'"

          if !server.run(has_gem_cmd)  # doesn't have this exact version
            puts "~> Installing engineyard-serverside on #{server.hostname}"

            system(Escape.shell_command([
              'scp', '-i', "#{ENV['HOME']}/.ssh/internal",
              "-o", "StrictHostKeyChecking=no",
              local_gem_file,
             "#{config.user}@#{server.hostname}:#{remote_gem_file}",
            ]))
            server.run("sudo #{gem_binary} install --no-rdoc --no-ri '#{remote_gem_file}'")
          end
        end
      end))
    end

    private

    def assemble_instance_hashes
      options[:instances].collect { |hostname|
        { :hostname => hostname,
          :roles => options[:instance_roles][hostname].to_s.split(','),
          :name => options[:instance_names][hostname]
        }
      }
    end
  end
end
