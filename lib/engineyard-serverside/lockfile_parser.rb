require 'yaml'
module EY
  module Serverside
    class LockfileParser

      attr_reader :bundler_version, :lockfile_version

      def initialize(lockfile_contents)
        @lockfile_version, @bundler_version = Parse106.new(lockfile_contents).parse
      end

      private

      class BaseParser
        def initialize(contents)
          @contents = contents
        end
        def parse
          raise "Unknown lockfile format #{@contents[0,50]}..."
        end
      end

      class Parse09 < BaseParser
        def parse
          from_yaml = safe_yaml_load(@contents)
          unless from_yaml.is_a?(Hash)
            return super
          end
          bundler_version = from_yaml['specs'].map do |spec|
            # spec is a one-element hash: the key is the gem name, and
            # the value is {"version" => the-version}.
            if spec.keys.first == "bundler"
              spec.values.first["version"]
            end
          end.compact.first
          [:bundler09, bundler_version]
        end
        def safe_yaml_load(loadable)
          YAML.load(loadable) #won't always raise... soemtimes parses the contents as 1 big string
        rescue ArgumentError => e  # not yaml
          nil
        end
      end

      class Parse10 < Parse09
        def parse
          unless @contents.index(/^DEPENDENCIES/)
            return super
          end
          dep_section = ""
          in_dependencies_section = false
          @contents.each_line do |line|
            if line =~ /^DEPENDENCIES/
              in_dependencies_section = true
            elsif line =~ /^\S/
              in_dependencies_section = false
            elsif in_dependencies_section
              dep_section << line
            end
          end

          unless dep_section.length > 0
            raise "Couldn't parse #{@contents}; exiting"
            exit(1)
          end

          result = dep_section.scan(/^\s*bundler\s*\(=\s*([^\)]+)\)/).first
          bundler_version = result ? result.first : nil
          [:bundler10, bundler_version]
        end
      end

      class Parse106 < Parse10
        def parse
          unless @contents.index(/^METADATA/)
            return super
          end
          meta_section = ""
          in_meta_section = false
          @contents.each_line do |line|
            if line =~ /^METADATA/
              in_meta_section = true
            elsif line =~ /^\S/
              in_meta_section = false
            elsif in_meta_section
              meta_section << line
            end
          end

          unless meta_section.length > 0
            raise "Couldn't parse #{@contents}; exiting"
            exit(1)
          end

          result = meta_section.scan(/^\s*version:\s*(.*)$/).first
          bundler_version = result ? result.first : nil
          [:bundler10, bundler_version]
        end
      end

    end
  end
end
