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
      environment.setup_repositories!
      environment.setup_gemfiles!
      environment.setup_bundles!

    end

    desc "status", "Check the status of a development environment"

    def status

      check_dependencies

      say_status environment.get_packages_status

    end

    desc "update", "Update the environment"

    def update

      check_dependencies

      environment.update_repositories!
      environment.setup_gemfiles!
      environment.setup_bundles!

    end

  end

end
