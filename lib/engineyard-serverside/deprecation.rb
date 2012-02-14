require 'engineyard-serverside/shell/helpers'

module EY
  module Serverside
    def self.deprecation_warning(msg)
      $stderr.puts "DEPRECATION WARNING: #{msg}"
    end

    def self.const_missing(const)
      if const == :LoggedOutput
        EY::Serverside.deprecation_warning("EY::Serverside::LoggedOutput has been deprecated. Use EY::Serverside::Shell::Helpers instead.")
        EY::Serverside::Shell::Helpers
      else
        super
      end
    end
  end

  def self.const_missing(const)
    if EY::Serverside.const_defined?(const)
      EY::Serverside.deprecation_warning("EY::#{const} has been deprecated. use EY::Serverside::#{const} instead")
      EY::Serverside.class_eval(const.to_s)
    else
      super
    end
  end

  def self.node
    EY::Serverside.deprecation_warning("EY.node has been deprecated. use EY::Serverside.node instead")
    EY::Serverside.node
  end

  def self.dna_json
    EY::Serverside.deprecation_warning("EY.dna_json has been deprecated. use EY::Serverside.dna_json instead")
    EY::Serverside.dna_json
  end
end
