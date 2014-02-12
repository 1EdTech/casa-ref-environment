require 'thor'
require 'casa/environment/support/dsl/say'
require 'casa/environment/support/dsl/environment'
require 'casa/environment/support/dsl/check_dependencies'
require 'casa/environment/configuration'

module Env

  class Dev < Thor

    include CASA::Environment::Support::DSL::Say
    include CASA::Environment::Support::DSL::Environment
    include CASA::Environment::Support::DSL::CheckDependencies

    attr_reader :config

    def initialize args = [], options = {}, config = {}

      super args, options, config

      @config = CASA::Environment::Configuration.new
      @config.load_config_file! 'config/base.json'
      @config.load_config_file! 'config/dev.json'

    end

    desc "setup", "Setup the development environment"

    def setup

      check_dependencies

      environment.make_workspace_directory!
      environment.setup_package_repositories!
      environment.setup_package_gemfiles!
      environment.setup_package_bundles!

    end

    desc "status", "Check the status of a development environment"

    def status

      check_dependencies

      say_status environment.get_packages_status

    end

    desc "update", "Update the development environment"

    def update

      check_dependencies

      environment.update_package_repositories!
      environment.setup_package_gemfiles!
      environment.setup_package_bundles!

    end

    desc "configure", "Create development environment configuration"

    def configure

      check_dependencies

      environment.configure_packages!

    end

    desc "reset", "Reset development environment configuration"

    def reset

      check_dependencies

      environment.reset_packages!

    end

    desc "destroy", "Destroy the development environment"

    def destroy

      check_dependencies

      environment.destroy_package_directories!
      environment.destroy_workspace_directory_if_empty!

    end

  end

end
