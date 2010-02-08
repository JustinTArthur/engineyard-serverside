$:.unshift File.expand_path('../../vendor/thor/lib', File.dirname(__FILE__))

require 'thor'

module Ey
  module Server
    class CLI < Thor
      class_option :migrate, :type     => :boolean,
                             :default  => true,
                             :desc     => "Run migrations with this deploy",
                             :aliases  => ["-m"]

      class_option :branch,  :type     => :string,
                             :default  => "master",
                             :desc     => "Branch to deploy from, defaults to master",
                             :aliases  => ["-b"]

      method_option :app,    :type     => :string,
                             :required => true,
                             :desc     => "Application to deploy",
                             :aliases  => ["-a"]
      desc "deploy", "Deploy code from /data/<app>"
      def deploy
        Ey::Server::Deploy.run(options)
      end

      method_option :app,    :type     => :string,
                             :required => true,
                             :desc     => "Application to deploy",
                             :aliases  => ["-a"]
      desc "update", "Update code locally, push to all other instances and run the deploy"
      def update
        Ey::Server::Update.run(options)
      end
    end
  end
end