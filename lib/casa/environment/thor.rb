require 'thor'
require 'casa/environment/support/dsl/say'
require 'casa/environment/support/dsl/environment'
require 'casa/environment/support/dsl/check_dependencies'
require 'casa/environment/configuration'

module Casa
  module Environment
    class Thor < ::Thor

      include CASA::Environment::Support::DSL::Say
      include CASA::Environment::Support::DSL::Environment
      include CASA::Environment::Support::DSL::CheckDependencies

      attr_reader :config

      class_option :config,
                   :aliases => ['c'],
                   :type => :string,
                   :default => 'config/dev.json',
                   :desc => 'Path to configuration file'

      no_tasks do

        def prepare

          @config = CASA::Environment::Configuration.new
          @config.load_config_file! 'config/base.json'
          @config.load_config_file! options.config

        end

      end

      desc "setup", "Setup the development environment"

      def setup

        prepare

        check_dependencies

        environment.make_workspace_directory!
        environment.setup_package_repositories!
        environment.setup_package_gemfiles!
        environment.setup_package_bundles!

      end

      desc "status", "Check the status of a development environment"

      def status

        prepare

        check_dependencies

        say_status environment.get_packages_status

      end

      desc "update", "Update the development environment"

      def update

        prepare

        check_dependencies

        environment.update_package_repositories!
        environment.setup_package_gemfiles!
        environment.setup_package_bundles!

      end

      desc "configure", "Create development environment configuration"

      def configure

        prepare

        check_dependencies

        environment.configure_packages!

      end

      desc "reset", "Reset development environment configuration"

      def reset

        prepare

        check_dependencies

        environment.reset_packages!

      end

      desc "destroy", "Destroy the development environment"

      def destroy

        prepare

        check_dependencies

        environment.destroy_package_directories!
        environment.destroy_workspace_directory_if_empty!

      end

    end
  end
end
