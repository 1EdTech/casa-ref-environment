require 'thor'
require 'systemu'
require 'bundler'
require 'pathname'
require 'fileutils'
require 'json'

class Dev < Thor

  PACKAGES = [
    'casa-receiver',
    'casa-publisher',
    'casa-payload',
    'casa-operation-translate',
    'casa-operation-squash',
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

      path = path_to package
      repo = git_repo package

      say "Downloading #{package}", :bold

      if Dir.exists? path

        say "Skipping #{package} as path already exists", [:magenta, :bold]
        say " - Path: #{path}", :magenta

      else

        managed_packages << package

        say "Cloning repository", [:green,:bold]
        say " - Repository: #{repo}", :green
        say " - Path: #{path}", :green
        status, stdout, stderr = systemu "git clone #{repo} #{path}"

        unless status.success?
          FileUtils.rm_rf path
          say_fail "Clone of #{repo} into #{path} failed!"
        end

      end

    end

    unless settings['configure'] == 'never'

      PACKAGES.each do |package|

        path = path_to package
        gemfile_path = path + 'Gemfile'
        gemspec_path = path + "#{package}.gemspec"

        say "Configuring #{package}", :bold

        if managed_packages.include?(package) || settings['configure'] == 'always'

          say "Reading gemspec", [:green,:bold]
          say " - Path: #{gemspec_path}", :green
          dependencies = get_gemspec_dependencies package

          say "Writing development paths to Gemfile", [:green, :bold]
          say " - Path: #{gemfile_path}", :green
          File.open(gemfile_path, 'w') { |file| file.write gemfile_content dependencies }


        else

          say "Skipping #{package} as path already exists", [:magenta, :bold]
          say " - Path: #{path}", :magenta

        end

      end

    end

    unless settings['initialize'] == 'never'

      PACKAGES.each do |package|

        say "Initializing #{package}", :bold

        path = path_to package

        if managed_packages.include?(package) || settings['initialize'] == 'always'

          Dir.chdir path do
            Bundler.with_clean_env do
              say "Executing bundle", [:green, :bold]
              status, stdout, stderr = systemu "bundle"
              say stdout, :green
            end
          end

        else

          say "Skipping #{package} as path already exists", [:magenta, :bold]
          say " - Path: #{path}", :magenta

        end

      end

    end

    say "Setup complete", :bold

  end

  no_commands do

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

    def gemfile_content dependencies

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
        gemfile.join("
")

    end

  end

end