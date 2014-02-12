require 'json'
require 'sequel'
require 'casa/environment/support/gemfile'

module CASA
  module Environment
    module PackageConfiguration
      class Engine

        attr_reader :package

        DB_ADAPTER_REQUIREMENTS = {
          'mysql2' => ['mysql2'],
          'tinytds' => ['tiny_tds'],
          'sqlite' => ['sqlite3']
        }

        def initialize package
          @package = package
        end

        def db
          unless @db
            db_load_dependencies!
            @db = Sequel.connect db_connection_settings
          end
          @db
        end

        def configure!
          create_engine_settings!
          create_attributes_settings!
          add_gems!
          setup_persistence!
        end

        def reset!
          reset_engine_settings!
          reset_attributes_settings!
          package.reset_gemfile!
          reset_persistence!
        end

        # Generic Helpers

        def db_connection_settings
          package.config.settings['engine']['database'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        end

        def db_connection_adapter
          db_connection_settings[:adapter]
        end

        # Configure Helpers

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

        def setup_persistence!

          reset_persistence!

          setup_payload_persistence!
          setup_peer_persistence!
          load_persistence_data!

        end

        def setup_payload_persistence!
          [
            'adj_in_payloads',
            'adj_out_payloads',
            'local_payloads'
          ].each do |table|
            db.run "CREATE TABLE `#{table}` (
              `id` varchar(255) NOT NULL,
              `originator_id` varchar(36) NOT NULL,
              `data` text NOT NULL,
              PRIMARY KEY (`id`,`originator_id`)
            )"
          end
        end

        def setup_peer_persistence!
          db.run 'CREATE TABLE IF NOT EXISTS `adj_in_peers` (
            `name` varchar(255) NOT NULL,
            `uri` text NOT NULL,
            `secret` varchar(255) DEFAULT NULL,
            PRIMARY KEY (`name`)
          )'
        end

        def load_persistence_data!
          package.config.persistence.each do |table, rows|
            table = table.to_sym
            rows.each do |row|
              if table.match /_payloads$/
                row = {
                  "id" => row['identity']['id'],
                  "originator_id" => row['identity']['originator_id'],
                  "data" => row.to_json
                }
              end
              db[table].insert row
            end
          end
        end

        # Reset Helpers

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

        def reset_persistence!
          [
            'adj_in_payloads',
            'adj_in_peers',
            'adj_out_payloads',
            'local_payloads'
          ].each do |table|
            db.run "DROP TABLE IF EXISTS `#{table}`"
          end
        end

        private

        def db_load_dependencies!

          DB_ADAPTER_REQUIREMENTS[db_connection_adapter].each do |dep|
            begin
              require dep
            rescue LoadError
              abort "\e[31m\e[1mDatabase adapter '#{db_connection_adapter}' requires `#{dep}' gem\e[0m\n\e[31mRun 'bundle install' to resolve (must not '--without #{db_connection_adapter}')'"
            end
          end
        end

      end
    end
  end
end