require 'thor'
require 'casa/bootstrap'

module Env

  class Dev < Thor

    include CASA::Bootstrap::Support::Thor::Say

    def initialize args = [], options = {}, config = {}

      super args, options, config

      @config = CASA::Bootstrap::Configuration.new 'config/dev.json'

    end

    def check_dependencies

      system = CASA::Bootstrap::System.new @config
      say_fail "Git must be installed" unless system.has_git?
      say_fail "Bundler must be installed" unless system.has_bundler?

    end

    desc "setup", "Setup the development environment"

    def setup

      check_dependencies

      environment = CASA::Bootstrap::Environment.new @config
      environment.make_workspace_directory!
      environment.setup_repositories!
      environment.setup_gemfiles!
      environment.setup_bundles!

    end

  end

end
