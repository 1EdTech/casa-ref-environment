require 'thor'
require 'systemu'
require 'bundler'
require 'pathname'
require 'fileutils'
require 'json'

class Dev < Thor

  PACKAGES = [
    'casa-engine',
    'casa-receiver',
    'casa-publisher',
    'casa-payload',
    'casa-support',
    'casa-operation',
    'casa-operation-translate',
    'casa-operation-squash',
    'casa-operation-filter',
    'casa-operation-transform',
    'casa-attribute',
    'casa-attribute-title'
  ]

  desc "destroy", "Destroy all development packages"

  def destroy

    PACKAGES.each do |package|

      say "Destroying #{package}", :bold

      path = path_to package

      if Dir.exists? path

        say "Deleting #{path}", :red
        FileUtils.rm_rf path

      else

        say "Skipping #{package} as #{path} does not exist", :cyan

      end

    end

  end

  desc "setup", "Install all development packages"

  method_option :configure,
                :type => :string,
                :enum => ['never','installed','always'],
                :default => 'installed',
                :desc => 'Whether to write development environment to Gemfile, and whether or not to always run or only on packages actually downloaded by setup'

  method_option :initialize,
                :type => :string,
                :enum => ['never','installed','always'],
                :default => 'installed',
                :desc => 'Whether to run bundler or not, and whether to always run or only on packages actually downloaded by setup'

  def setup

    say "Initializing setup", :bold

    status, stdout, stderr = systemu "git --version"
    say_fail "Git must be installed" unless status.success?

    status, stdout, stderr = systemu "bundle --version"
    say_fail "Bundler must be installed" unless status.success?

    unless Dir.exists? base_path
      say "Creating development workspace #{base_path}", :green
      FileUtils.mkdir_p base_path
    end

    managed_packages = []

    PACKAGES.each do |package|

      managed_packages << package if download_package package

    end

    unless settings['configure'] == 'never'

      PACKAGES.each do |package|

        say "Configuring #{package}", :bold

        if managed_packages.include?(package) || settings['configure'] == 'always'

          configure_package package

        else

          say "Skipping #{package} as path already exists", [:magenta, :bold]
          say " - Path: #{path_to package}", :magenta

        end

      end

    end

    unless settings['initialize'] == 'never'

      PACKAGES.each do |package|

        say "Initializing #{package}", :bold

        if managed_packages.include?(package) || settings['initialize'] == 'always'

          initialize_package package

        else

          say "Skipping #{package} as path already exists", [:magenta, :bold]
          say " - Path: #{path_to package}", :magenta

        end

      end

    end

    say "Setup complete", :bold

  end

  desc "status", "Status current dev environment"

  def status

    PACKAGES.each do |package|

      path = path_to package

      say "Status for #{package}", [:green, :bold]

      if Dir.exists? path

        Dir.chdir path do
          status, stdout, stderr = systemu "git fetch origin"
          status, stdout, stderr = systemu "git status --short --branch"
          say "  Branch:", :bold
          say "    #{stdout.match(/^## (.*)$/)[1]}"
          changes = stdout.split('
').select(){ |line| !(line.match(/^##/)) }
          if changes.length > 0
            say "  Changes:", :bold
            changes.each { |line| say "   #{line}" }
          end
        end

      else

        say "  Package is not installed locally", [:red, :bold]

      end

    end

  end

  desc "update", "Update all development packages"

  def update

    PACKAGES.each do |package|

      say "Updating #{package}", :bold

      path = path_to package

      download_package package unless Dir.exists? path

      Dir.chdir path do

        status, stdout, stderr = systemu "git branch"
        branch = stdout.match(/^\* (.*)$/)[1]
        status, stdout, stderr = systemu "git fetch origin #{branch}"
        status, stdout, stderr = systemu "git status --short --branch"

        if stdout.match(/^## .*\[behind .*\].*$/)
          say "Merging #{package}", [:green, :bold]
          status, stdout, stderr = systemu "git merge FETCH_HEAD"
          say stdout
          say "Configuring #{package}", [:green, :bold]
          configure_package package
          say "Initializing #{package}", [:green, :bold]
          initialize_package package
        else
          say "Skipping #{package} as already up-to-date", [:magenta, :bold]
        end

      end

    end

  end

  no_commands do

    def download_package package

      path = path_to package
      repo = git_repo package

      say "Downloading #{package}", :bold

      if Dir.exists? path

        say "Skipping #{package} as path already exists", [:magenta, :bold]
        say " - Path: #{path}", :magenta

        false

      else

        say "Cloning repository", [:green,:bold]
        say " - Repository: #{repo}", :green
        say " - Path: #{path}", :green
        status, stdout, stderr = systemu "git clone #{repo} #{path}"

        unless status.success?
          FileUtils.rm_rf path
          say_fail "Clone of #{repo} into #{path} failed!"
        end

        true

      end

    end

    def configure_package package

      path = path_to package
      gemfile_path = path + 'Gemfile'
      gemspec_path = path + "#{package}.gemspec"

      say "Reading gemspec", [:green,:bold]
      say " - Path: #{gemspec_path}", :green
      dependencies = get_gemspec_dependencies package

      say "Writing development paths to Gemfile", [:green, :bold]
      say " - Path: #{gemfile_path}", :green
      File.open(gemfile_path, 'w') { |file| file.write gemfile_content package, dependencies }
      Dir.chdir(path){ systemu "git update-index --assume-unchanged Gemfile" }

    end

    def initialize_package package

      path = path_to package

      Dir.chdir path do
        Bundler.with_clean_env do
          say "Executing bundle", [:green, :bold]
          case package
            when 'casa-engine'
              command = 'bundle --without mssql'
            else
              command = 'bundle'
          end
          status, stdout, stderr = systemu command
          say stdout, :green
        end
      end

    end

    def settings_file
      Pathname.new(__FILE__).parent.realpath + 'config.json'
    end

    def settings
      JSON.parse(File.read settings_file).merge options.to_hash
    end

    def say_fail message
      say "ERROR - #{message}", [:red,:bold]
      exit 1
    end

    def base_path
      @base_path ||= settings.has_key?('path') ? Pathname.new(__FILE__).parent + settings['path'] : Pathname.new(__FILE__).parent
    end

    def path_to package
      base_path + package
    end

    def git_repo package
      "https://github.com/AppSharing/#{package}.git"
    end

    def get_gemspec_dependencies package, ignores = []

      gemspec_path = path_to(package) + "#{package}.gemspec"
      spec = Gem::Specification.load gemspec_path.to_s

      dependencies = spec.dependencies.map(){ |package|
        package.name
      }.select(){ |package|
        PACKAGES.include?(package) and !ignores.include?(package)
      }

      case package
        when 'casa-receiver'
          dependencies |= PACKAGES.select(){ |dependency|
            dependency.match(/^casa-attribute-/) and !dependencies.include?(dependency)
          }
      end

      dependencies.each do |dependency|
        dependencies |= get_gemspec_dependencies dependency, dependencies
      end

      dependencies
    end

    def gemfile_content package, dependencies

        gemfile = []
        gemfile << "source 'https://rubygems.org'"
        gemfile << "gemspec"
        gemfile << "group :development do"

        dependencies.each do |dependency|
          if PACKAGES.include? dependency
            gemfile << "  gem '#{dependency}', '>= 0', :path => '../#{dependency}'"
          end
        end

        gemfile << "end"
        case package
          when 'casa-engine'
            gemfile << "group(:mysql2){ gem 'mysql2' }"
            gemfile << "group(:mssql){ gem 'tiny_tds' }"
            gemfile << "group(:sqlite){ gem 'sqlite3' }"
        end
        gemfile.join("
")

    end

  end

end
