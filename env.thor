require 'pathname'
Dir.glob(Pathname.new(__FILE__).parent.realpath + 'task' + "**/*.rb").each { |r| require r }