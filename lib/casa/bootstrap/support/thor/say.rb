module CASA
  module Bootstrap
    module Support
      module Thor
        module Say

          def say_fail message
            say "ERROR - #{message}", [:red,:bold]
            exit 1
          end

        end
      end
    end
  end
end