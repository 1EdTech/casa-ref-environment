require 'fileutils'

module CASA
  module Bootstrap
    class Package

      attr_reader :name
      attr_reader :path
      attr_reader :config
      attr_reader :environment

      def initialize name, path, config, environment

        @name = name
        @path = path
        @config = config
        @environment = environment

      end

      def exists?

        Dir.exists? path

      end

      def setup_git_repository! overwrite = false

        if setup_dir! overwrite
          setup_git!
          pull_remote_branch!
          setup_remotes!
          setup_branch_config!
          true
        else
          false
        end

      end

      def setup_dir! overwrite = false

        if exists?
          if overwrite
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
          environment.exec :git, "pull #{config['remotes'][config['remote']]} #{config['branch']}"
        end

      end

      def setup_remotes!

        in_dir do
          config['remotes'].each do |remote_name, remote_path|
            environment.exec :git, "remote add #{remote_name} #{remote_path}"
          end
        end

      end

      def setup_branch_config!

        in_dir do
          environment.exec :git, "config branch.#{config['branch']}.remote #{config['remote']}"
          environment.exec :git, "config branch.#{config['branch']}.merge refs/heads/#{config['branch']}"
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