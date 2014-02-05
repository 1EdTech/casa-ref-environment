require 'thor'
require 'casa/bootstrap/support/dsl/say'
require 'casa/bootstrap/support/dsl/environment'
require 'casa/bootstrap/support/dsl/check_dependencies'
require 'casa/bootstrap/configuration'

module Env

  class Dev < Thor

    include CASA::Bootstrap::Support::DSL::Say
    include CASA::Bootstrap::Support::DSL::Environment
    include CASA::Bootstrap::Support::DSL::CheckDependencies

    attr_reader :config

    def initialize args = [], options = {}, config = {}

      super args, options, config

      @config = CASA::Bootstrap::Configuration.new 'config/dev.json'

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

  end

end
