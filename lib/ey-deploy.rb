$LOAD_PATH.push(File.expand_path("ey-deploy", File.dirname(__FILE__)))

require 'strategies/git'
require 'task'
require 'server'
require 'deploy'
require 'update'
require 'cli'

module EY
  DNA_FILE = "/etc/chef/dna.json"
end