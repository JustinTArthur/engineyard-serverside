require 'spec_helper'

describe "the bundler version retrieved from the lockfile" do
  def get_full_path(file)
    File.expand_path("../support/lockfiles/#{file}", __FILE__)
  end
  def get_version(file)
    @config = EY::Serverside::Deploy::Configuration.new('deploy_to' => 'dontcare')
    EY::Serverside::DeployBase.new(@config).get_bundler_installer(get_full_path(file)).version
  end

  it "raises an error with pre 0.9 bundler lockfiles" do
    lambda { get_version('0.9-no-bundler') }.should raise_error(RuntimeError, /Malformed or pre bundler-1.0.0 Gemfile.lock/)
    lambda { get_version('0.9-with-bundler') }.should raise_error(RuntimeError, /Malformed or pre bundler-1.0.0 Gemfile.lock/)
  end

  it "returns the default version for a 1.0 lockfile without a bundler dependency" do
    get_version('1.0-no-bundler').should == EY::Serverside::LockfileParser::DEFAULT
  end

  it "gets the version from a 1.0.0.rc.1 lockfile w/dependency on 1.0.0.rc.1" do
    # This is a real, customer-generated lockfile
    get_version('1.0.0.rc.1-with-bundler').should == '1.0.0.rc.1'
  end

  it "gets the version from a 1.0.6 lockfile w/dependency on 1.0.6" do
    # This is a real, customer-generated lockfile
    get_version('1.0.6-with-bundler').should == '1.0.6'
  end

  it "gets the version from a 1.0.6 lockfile w/dependency on 1.0.6 (bundled ~> 1.0.0)" do
    # This is a real, customer-generated lockfile
    get_version('1.0.6-with-any-bundler').should == '1.0.6'
  end

  it "gets the version from a 1.0.6 lockfile w/o dependency" do
    # This is a real, customer-generated lockfile
    get_version('1.0.6-no-bundler').should == '1.0.6'
  end

  it "raises an error if it can't parse the file" do
    lambda { get_version('not-a-lockfile') }.should raise_error(RuntimeError, /Malformed or pre bundler-1.0.0 Gemfile.lock/)
  end

  context "fetching the right version number" do
    subject { EY::Serverside::LockfileParser.new(File.read(get_full_path('1.0.6-no-bundler'))) }

    it "uses the default version when there is no bundler version" do
      subject.fetch_version(nil, nil).should == EY::Serverside::LockfileParser::DEFAULT
    end

    it "uses the given version when the qualifier is `='" do
      subject.fetch_version('1.0.1', '=').should == '1.0.1'
    end

    it "uses the default version when we get a pessimistic qualifier and is lower than the default version" do
      subject.fetch_version('1.0.1', '~>').should == '1.0.10'
    end

    it "uses the given version when we get a pessimistic qualifier that doesn't match the default version" do
      subject.fetch_version('1.1.0', '~>').should == '1.1.0'
    end

    it "uses the given version when it's geater of equal than the default version" do
      subject.fetch_version('1.1.0', '>=').should == '1.1.0'
    end

    it "uses the default version when the given version is lower" do
      subject.fetch_version('1.0.1', '>=').should == EY::Serverside::LockfileParser::DEFAULT
    end

    it "selects only the first version expression" do
      scan = subject.scan_bundler 'bundler (>=1.0.1, <2.0.0)'
      scan.last.should == '1.0.1'
    end
  end
end
