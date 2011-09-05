require File.dirname(__FILE__) + '/spec_helper'
require 'fileutils'

describe "the EY::Serverside::Deploy API" do
  it "calls tasks in the right order" do
    class TestDeploy < EY::Serverside::Deploy
      # This happens before require_custom_tasks, so it's not
      # overrideable. That's why it's not in @call_order.
      def update_repository_cache() end

      # cheat a bit; we don't actually want to do these things
      def require_custom_tasks() end
      def callback(*_) end
      def puts(*_) 'stfu' end

      attr_reader :call_order
      def initialize(*a)
        super
        @call_order = []
      end

      def push_code()                              @call_order << 'push_code'                              end
      def copy_repository_cache()                  @call_order << 'copy_repository_cache'                  end
      def create_revision_file()                   @call_order << 'create_revision_file'                   end
      def bundle()                                 @call_order << 'bundle'                                 end
      def symlink_configs()                        @call_order << 'symlink_configs'                        end
      def migrate()                                @call_order << 'migrate'                                end
      def symlink()                                @call_order << 'symlink'                                end
      def restart()                                @call_order << 'restart'                                end
      def cleanup_old_releases()                   @call_order << 'cleanup_old_releases'                   end
      def conditionally_enable_maintenance_page()  @call_order << 'conditionally_enable_maintenance_page'  end
      def disable_maintenance_page()               @call_order << 'disable_maintenance_page'               end

      def generate_database_yml() end
    end

    setup_dna_json

    td = TestDeploy.new(EY::Serverside::Deploy::Configuration.new('app' => 'myfirstapp'))
    td.deploy
    td.call_order.should == %w(
      push_code
      copy_repository_cache
      create_revision_file
      bundle
      symlink_configs
      conditionally_enable_maintenance_page
      migrate
      symlink
      restart
      disable_maintenance_page
      cleanup_old_releases)
  end

  describe "task overrides" do
    class TestQuietDeploy < EY::Serverside::Deploy
      def puts(*_) 'quiet' end
    end

    before(:each) do
      @tempdir = Dir.mktmpdir('custom_deploy_spec.XXXXX')
      @config = EY::Serverside::Deploy::Configuration.new('repository_cache' => @tempdir)
      @deploy = TestQuietDeploy.new(@config)
    end

    after do
      FileUtils.rm_rf(@tempdir)
    end

    def write_eydeploy(relative_path, contents = "def got_new_methods() 'from the file on disk' end")
      FileUtils.mkdir_p(File.join(@tempdir, File.dirname(relative_path)))

      File.open(File.join(@tempdir, relative_path), 'w') do |f|
        f.write contents
      end
    end

    it "requires 'eydeploy.rb' and adds any defined methods to the deploy" do
      write_eydeploy 'eydeploy.rb'
      @deploy.require_custom_tasks.should be_true
      @deploy.got_new_methods.should == 'from the file on disk'
    end

    it "falls back to 'config/eydeploy.rb'" do
      write_eydeploy 'config/eydeploy.rb'
      @deploy.require_custom_tasks.should be_true
      @deploy.got_new_methods.should == 'from the file on disk'
    end

    it "lets you super up from any defined methods" do
      write_eydeploy 'eydeploy.rb', "def value() super << ' + derived' end"

      class TestDeploySuper < TestQuietDeploy
        def value() 'base' end
      end

      deploy = TestDeploySuper.new(@config)
      deploy.require_custom_tasks.should be_true
      deploy.value.should == "base + derived"
    end
  end
end
