require 'pathname'
Dir.glob(Pathname.new(__FILE__).parent.realpath + "package_configuration/**/*.rb").each { |r| require r }