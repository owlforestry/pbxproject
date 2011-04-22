require 'pbxproject'
require 'yaml'
begin
  require 'thor'
rescue LoadError
  $stderr.puts "To use CLI, please install Thor"
  exit
end

module PBXProject
  class CLI < Thor
    desc "parse", "Parses pbxproject file and outputs its"
    method_option :input
    method_option :output
    def parse
      pbx = PBXProject.new :file => options[:input]
      pbx.parse
      
      puts pbx.to_pbx
    end
  end
end
