require 'fileutils'
require 'ostruct'
require 'bundler'
require 'casa/environment/support/gemfile'
require 'casa/environment/package_configuration'

module CASA
  module Environment
    class Package

      attr_reader :name
      attr_reader :path
      attr_reader :config
      attr_reader :environment

      def initialize name, path, config, environment

        @name = name
        @path = path
        @config = OpenStruct.new config
        @environment = environment
        @new = !exists?

      end

      def new?

        @new

      end

      def exists?

        Dir.exists? path

      end

      # FULL ACTIONS

      def setup_git_repository! *options

        if setup_dir! *options
          @new = true
          setup_git!
          pull_remote_branch!
          setup_remotes!
          setup_branch_config!
          true
        else
          false
        end

      end

      def update_git_repository! *options

        unless @new

          fetch_git_repository!

          unless git_branch_is_up_to_date?

            unset_gemfile_git_ignore!
            cmd :git, 'checkout Gemfile'
            cmd :git, "merge #{config.remote}/#{git_branch}"
            @new = true
            true

          else

            false

          end

        else

          false

        end

      end

      def setup_gemfile! *options

        if new? or options.include? :overwrite
          gemfile = CASA::Environment::Support::Gemfile.new path + 'Gemfile'
          environment.each_package { |package| gemfile.set_local_package package.name, "../#{package.name}" }
          gemfile.save!
          set_gemfile_git_ignore!
          true
        else
          false
        end

      end

      def setup_bundle! *options

        if new? or options.include? :overwrite
          if config.bundler and config.bundler.has_key?('install')
            install_command = config.bundler['install']
          else
            install_command = 'install'
          end
          Bundler.with_clean_env do
            cmd :bundler, install_command
          end
          true
        else
          false
        end

      end

      def configure!

        invoke_configuration_handler_method :configure!

      end

      def get_status *options

        if exists?
          {
            :git => get_git_status
          }
        else
          false
        end

      end

      def get_git_status *options

        fetch_git_repository!
        status, stdout, stderr = cmd_result :git, 'status --short --branch'
        {
          :branch => stdout.match(/^## (.*)$/)[1],
          :changes => stdout.split('
                                   ').select(){ |line| !(line.match(/^##/)) }
        }

      end

      def reset!

        invoke_configuration_handler_method :reset!

      end

      def reset_gemfile!

        unset_gemfile_git_ignore!
        cmd :git, 'checkout Gemfile'
        setup_gemfile! :overwrite
        set_gemfile_git_ignore!
        setup_bundle! :overwrite

      end

      def destroy_directory! *options

        FileUtils.rm_rf path
        true

      end

      # PARTIAL ACTIONS

      def setup_dir! *options

        if exists?
          if options.include? :overwrite
            FileUtils.rm_rf path
          else
            return false
          end
        end

        FileUtils.mkdir_p path

      end

      def setup_git!

        cmd :git, "init"

      end

      def pull_remote_branch!

        cmd :git, "pull #{config.remotes[config.remote]} #{config.branch}"

      end

      def setup_remotes!

        config.remotes.each do |remote_name, remote_path|
          cmd :git, "remote add #{remote_name} #{remote_path}"
        end

      end

      def setup_branch_config!

        cmd :git, "config branch.#{config.branch}.remote #{config.remote}"
        cmd :git, "config branch.#{config.branch}.merge refs/heads/#{config.branch}"

      end

      def configuration_handler

        begin
          handler_name = "CASA::Environment::PackageConfiguration::#{name.gsub(/^casa-/,'').split('-').map(&:capitalize).join('')}"
          klass = "CASA::Environment::PackageConfiguration::#{handler_name}".split('::').inject(Object){|o,c| o.const_get c}
          klass.new self
        rescue NameError
          nil
        end

      end

      def invoke_configuration_handler_method method

        configuration = configuration_handler

        if configuration
          configuration.send method
          true
        else
          false
        end

      end

      def set_gemfile_git_ignore!

        cmd :git, "update-index --assume-unchanged Gemfile"

      end

      def unset_gemfile_git_ignore!

        cmd :git, "update-index --no-assume-unchanged Gemfile"

      end

      def git_branch

        _, stdout, _ = cmd_result :git, 'branch'
        stdout.match(/^\* (.*)$/)[1]

      end

      def git_branch_is_up_to_date?

        in_dir do
          _, stdout, _ = environment.cmd_result :git, 'status --short --branch'
          stdout.match(/^## .*\[behind .*\].*$/).nil?
        end

      end

      def fetch_git_repository!

        cmd :git, "fetch #{config.remote}"

      end

      def cmd name, command

        in_dir do
          environment.cmd name, command
        end

      end

      def cmd_result name, command

        in_dir do
          environment.cmd_result name, command
        end

      end


      def in_dir

        Dir.chdir path do |path|
          yield path
        end

      end

    end
  end
end