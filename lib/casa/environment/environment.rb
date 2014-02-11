require 'fileutils'
require 'systemu'
require 'casa/environment/package'

module CASA
  module Environment
    class Environment

      attr_reader :config

      def initialize config

        @config = config
        @packages = nil

      end

      def exists?

        Dir.exists? config.path

      end

      def make_workspace_directory!

        unless exists?
          FileUtils.mkdir_p config.path
          true
        else
          false
        end

      end

      def setup_repositories! *args

        each_package { |package| package.setup_git_repository! *args  }

      end

      def update_repositories! *args

        setup_repositories! *args
        each_package { |package| package.update_git_repository! *args  }

      end

      def setup_gemfiles! *args

        each_package { |package| package.setup_gemfile! *args  }

      end

      def setup_bundles! *args

        each_package { |package| package.setup_bundle! *args  }

      end

      def get_packages_status *args

        each_package { |package| package.get_status *args }

      end

      # Returns array of package names for all packages that returned true
      def each_package

        result = {}
        packages.each do |name, package|
          result[name] = yield package
        end
        result

      end

      def packages

        unless @packages
          @packages = {}
          config.packages.each do |package_name, package_config|
            package_path = config.path + package_name
            @packages[package_name] = CASA::Environment::Package.new package_name, package_path, package_config, self
          end
        end
        @packages

      end

      def cmd name, command

        status, stdout, stderr = cmd_result name, command
        status.success?

      end

      def cmd_result name, command

        systemu "#{config.cmd.send name.to_sym} #{command}"

      end

    end
  end
end