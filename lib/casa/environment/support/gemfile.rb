module CASA
  module Environment
    module Support
      class Gemfile

        attr_reader :path
        attr_accessor :content

        def initialize path
          @path = path
          @content = File.read path
        end

        def set_local_package package_name, package_path
          pattern = /^(\s*gem ["']#{package_name}["'].*):git\s*=>\s*["'].*["'](.*)$/
          match = content.match pattern
          content.gsub! pattern, "#{match[1]}:path => '#{package_path}'#{match[2]}" if match
        end

        def set_gem gem_name, gem_options
          line = "gem '#{gem_name}', {#{gem_options.map(){|k,v|":#{k} => '#{v}'"}.join(', ')}}"
          content << "
#{line}" unless content.match /^\s*#{line}\s*$/
          puts line
          puts content
        end

        def save!
          File.open(path, 'w') { |file| file.write content }
        end

      end
    end
  end
end