require 'pathname'
Dir.glob(Pathname.new(__FILE__).parent.realpath + "**/*.rb").each { |r| require r }