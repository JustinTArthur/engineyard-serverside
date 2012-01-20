require 'spec_helper'
require 'tempfile'
require 'timecop'

class SampleLogUser
  include EY::Serverside::LoggedOutput
  def initialize
    EY::Serverside::LoggedOutput.logfile = tempfile.path
    EY::Serverside::LoggedOutput.verbose = true
  end
  
  

  def tempfile
    @tempfile ||= Tempfile.new('logged_output')
  end
end

describe EY::Serverside::LoggedOutput do
  before do
    EY::Serverside::LoggedOutput.enable_actual_info!
    @log_user = SampleLogUser.new
  end

  after do
    EY::Serverside::LoggedOutput.disable_actual_info!
  end

  it "has a timestamp before each line" do
    time1 = Time.local(2008, 9, 1, 12, 0, 0)
    time2 = Time.local(2008, 9, 1, 12, 10, 5)

    Timecop.freeze(time1)
    @log_user.debug('test1')
    @log_user.warning('test2')    
    Timecop.freeze(time2)
    @log_user.info('test3')

    @log_user.debug("test11\ntest12\ntest13")
    @log_user.warning("test21\ntest22\ntest23")    
    @log_user.info("test31\ntest32\ntest33")

    File.read(@log_user.tempfile.path).should == "#{time1.iso8601}: test1\n#{time1.iso8601}: !> WARNING: test2\n#{time2.iso8601}: test3\n#{time2.iso8601}: test11\n#{time2.iso8601}: test12\n#{time2.iso8601}: test13\n#{time2.iso8601}: !> WARNING: test21\n#{time2.iso8601}: !> test22\n#{time2.iso8601}: !> test23\n#{time2.iso8601}: test31\n#{time2.iso8601}: test32\n#{time2.iso8601}: test33\n"
  end
end