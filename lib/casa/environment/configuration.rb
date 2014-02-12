require 'json'
require 'ostruct'
require 'pathname'
require 'deep_merge'
require 'extend_method'

module CASA
  module Environment
    class Configuration

      class << self
        include ExtendMethod
      end

      attr_reader :base_path
      attr_reader :config_files
      attr_reader :config

      [:path, :cmd, :packages].each do |name|

        attr_reader name

        # extend attr_reader to refresh when config is stale
        extend_method name do
          compute_config! if @stale
          parent_method
        end

      end

      def initialize config_file = nil

        @base_path = Pathname.new(__FILE__).parent.parent.parent.parent.realpath
        reset_config!
        load_config_file! config_file if config_file

      end

      def reset_config!

        @config_files = []
        @config = {}
        @path = nil
        @packages = {}
        @cmd = {}
        @stale = false

      end

      def load_config_file! config_file_name

        config_file = @base_path + config_file_name
        load_config! JSON.parse File.read config_file
        @config_files.push config_file

      end

      def load_config! config

        @config.deep_merge! config
        @stale = true

      end

      def compute_config!

        @path = @base_path + @config['path']
        @cmd = OpenStruct.new @config['cmd']
        @packages = {}

        @config['packages'].each do |package_name, package_config|
          @packages[package_name] = {
            'remote' => 'origin',
            'branch' => 'master'
          }.merge package_config
        end

        @stale = false

      end

    end
  end
end