require 'json'
require 'casa/environment/support/gemfile'

module CASA
  module Environment
    module PackageConfiguration
      class Engine

        attr_reader :package

        def initialize package
          @package = package
        end

        def configure!
          create_engine_settings!
          create_attributes_settings!
          add_gems!
        end

        def reset!
          reset_engine_settings!
          reset_attributes_settings!
          package.reset_gemfile!
        end

        def create_engine_settings!
          package.in_dir do
            File.open('settings/engine.json', 'w') { |file| file.write package.config.settings['engine'].to_json }
            package.cmd :git, 'update-index --assume-unchanged settings/engine.json'
          end
        end

        def create_attributes_settings!
          package.in_dir do
            package.config.settings['attributes'].each do |name, settings|
              File.open("settings/attributes/#{name}.json", 'w') { |file| file.write settings.to_json }
              package.cmd :git, "update-index --assume-unchanged settings/attributes/#{name}.json"
            end
          end
        end

        def add_gems!
          package.in_dir do
            gemfile = CASA::Environment::Support::Gemfile.new 'Gemfile'
            package.config.gems.each do |gem_name, gem_options|
              gemfile.set_gem gem_name, gem_options
            end
            gemfile.save!
          end
        end

        def reset_engine_settings!
          package.in_dir do
            FileUtils.rm_f 'settings/engine.json'
          end
        end

        def reset_attributes_settings!
          package.in_dir do
            FileUtils.rm_rf 'settings/attributes'
            package.cmd :git, 'checkout settings/attributes'
          end
        end

      end
    end
  end
end