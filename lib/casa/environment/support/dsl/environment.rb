require 'casa/environment/environment'

module CASA
  module Environment
    module Support
      module DSL
        module Environment

          def environment
            @environment ||= CASA::Environment::Environment.new config
          end

        end
      end
    end
  end
end