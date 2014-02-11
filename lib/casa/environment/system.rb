require 'systemu'

module CASA
  module Environment
    class System

      attr_reader :config

      def initialize config
        @config = config
      end

      def has_dependency? test
        status, stdout, stderr = systemu test
        status.success?
      end

      def has_git?
        has_dependency? "#{@config.cmd.git} --version"
      end

      def has_bundler?
        has_dependency? "#{@config.cmd.bundler} --version"
      end

    end
  end
end