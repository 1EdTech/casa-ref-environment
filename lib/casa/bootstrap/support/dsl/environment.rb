require 'casa/bootstrap/environment'

module CASA
  module Bootstrap
    module Support
      module DSL
        module Environment

          def environment
            @environment ||= CASA::Bootstrap::Environment.new config
          end

        end
      end
    end
  end
end