require "colorize"

module Warden
	class Watcher
		@config  : Config::YAML_Config
		@project : Config::YAML_Project | Nil

		def initialize ( @config )            
			begin
				@project = Config.load_project @config.target
				STDERR << "#{@config.target.colorize(:red)} doesn't exists!\n"
			rescue
			end

			if @project.nil?
			else
			end


		end
	end
end

config = Config.load_config "config.yml"
unless config.nil?
	watcher = Warden::Watcher.new config
end
