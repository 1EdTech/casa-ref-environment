require 'json'
require 'ostruct'
require 'pathname'

module CASA
  module Environment
    class Configuration

      attr_reader :base_path
      attr_reader :config_file
      attr_reader :path
      attr_reader :packages
      attr_reader :exec

      def initialize config_file

        @base_path = Pathname.new(__FILE__).parent.parent.parent.parent.realpath
        @config_file = @base_path + config_file

        config = JSON.parse File.read @config_file

        @path = @base_path + config['path']
        @exec = OpenStruct.new config['exec']
        @packages = {}

        config['packages'].each do |package_name, package_config|
          @packages[package_name] = {
            'remote' => 'origin',
            'branch' => 'master'
          }.merge package_config
        end

      end

    end
  end
end