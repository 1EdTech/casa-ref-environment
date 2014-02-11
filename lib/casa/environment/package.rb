require 'fileutils'
require 'ostruct'
require 'casa/environment/support/gemfile'

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
          in_dir do
            if config.bundler and config.bundler.has_key?('install')
              install_command = config.bundler['install']
            else
              install_command = 'install'
            end
            environment.exec :bundler, install_command
          end
          true
        else
          false
        end

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
        in_dir do
          environment.exec :git, "fetch #{config.remote}"
          status, stdout, stderr = environment.exec_result :git, 'status --short --branch'
          {
            :branch => stdout.match(/^## (.*)$/)[1],
            :changes => stdout.split('
').select(){ |line| !(line.match(/^##/)) }
          }
        end
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

        in_dir do
          environment.exec :git, "init"
        end

      end

      def pull_remote_branch!

        in_dir do
          environment.exec :git, "pull #{config.remotes[config.remote]} #{config.branch}"
        end

      end

      def setup_remotes!

        in_dir do
          config.remotes.each do |remote_name, remote_path|
            environment.exec :git, "remote add #{remote_name} #{remote_path}"
          end
        end

      end

      def setup_branch_config!

        in_dir do
          environment.exec :git, "config branch.#{config.branch}.remote #{config.remote}"
          environment.exec :git, "config branch.#{config.branch}.merge refs/heads/#{config.branch}"
        end

      end

      def set_gemfile_git_ignore!

        in_dir do
          environment.exec :git, "update-index --assume-unchanged Gemfile"
        end

      end

      def unset_gemfile_git_ignore!

        in_dir do
          environment.exec :git, "update-index --no-assume-unchanged Gemfile"
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