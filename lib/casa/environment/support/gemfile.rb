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

        def save!
          File.open(path, 'w') { |file| file.write content }
        end

      end
    end
  end
end