module CASA
  module Bootstrap
    module Support
      module DSL
        module Say

          def say_fail message
            say "ERROR - #{message}", [:red,:bold]
            exit 1
          end

          def say_status hash

            hash.each do |package_name, package_status|
              say package_name, :bold
              say "Branch: #{package_status[:git][:branch]}"
              if package_status[:git][:changes].size > 0
                say "Changes:"
                package_status[:git][:changes].each { |change| say " - #{change}" }
              end
            end

          end

        end
      end
    end
  end
end