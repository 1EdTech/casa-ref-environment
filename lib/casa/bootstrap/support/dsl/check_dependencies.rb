require 'casa/bootstrap/system'

module CASA
  module Bootstrap
    module Support
      module DSL
        module CheckDependencies

          def check_dependencies

            system = CASA::Bootstrap::System.new config
            say_fail "Git must be installed" unless system.has_git?
            say_fail "Bundler must be installed" unless system.has_bundler?

          end

        end
      end
    end
  end
end