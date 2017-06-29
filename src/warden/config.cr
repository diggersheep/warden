require "yaml"
require "colorize"

module Config
	class FileNotExistsException < Exception end
	class NotGitCmdException < Exception end

	# 
	GIT = [
		"none",
		"add",
		"commit",
		"pull",
		"push"
	]

	# mapping of main config file
	class YAML_Config
		YAML.mapping(
			target: String,
			delay:  UInt32,
			timeout: UInt32,
			precommand: Array( YAML_Config_Command )
		)
	end
	class YAML_Config_Command
		YAML.mapping(
			files: String,
			run:   String,
			git:   String
		)
	end

	# mapping of project config file
	class YAML_Project
		YAML.mapping(
			auto_commit_message: {
				type: String,
				key:  "auto-commit-message",
				nilable: true
			},
			timeout: {
				type: UInt32,
				nilable: true
			},
			watch: Array(YAML_Config_Command)
		)
	end


	private def self.check_git ( g : String ) : Bool
		GIT.each do |e|
			if g == e
				return true
			end
		end
		false
	end

	# load main configuration file and check some values
	def self.load_config ( filename : String ) : Config::YAML_Config
		min_timeout = 100_u32
		min_delay   = 250_u32

		data = "" # future file data

		unless File.file? filename # check if it's a file'
			raise Config::FileNotExistsException.new
		end

		# load data
		data = File.read filename # raise ERRNO

		# parse yaml file (not handle exception)
		conf = YAML_Config.from_yaml data # raise YAML::ParseException

		conf.precommand.each do |e|
			unless check_git e.git
				# invalid YAML variable
				raise YAML::ParseException.new "", 0, 0
			end
		end

		if conf.delay < min_delay
			conf.delay = min_delay
		end
		if conf.timeout < min_timeout
			conf.timeout = min_timeout
		end

		conf
	end

	def self.load_project ( filename : String ) : Config::YAML_Project
		data = "" # future file data

		#load data
		unless File.exists? filename
			raise Config::FileNotExistsException.new
		end

		data = File.read filename # raise ERRNO
		
		# parse yaml file (not handle exception)
		conf = YAML_Project.from_yaml data

		conf.watch.each do |e|
			unless check_git e.git
				raise YAML::ParseException.new "", 0, 0
			end
		end

		#  auto complete
		if conf.auto_commit_message.nil?
			conf.auto_commit_message = "\#{git-auto}"
		end

		conf
	end

	def self.load_config? ( filename : String ) : Config::YAML_Config
		begin
			config = Config.load_config filename
		rescue Errno
			STDERR << "You don't have permission for #{filename.colorize(:red)}!\n"
			exit 1
		rescue YAML::ParseException
			# not valid
			STDERR << "Fatal error! #{filename.colorize(:red)} is not valid!\n"
			exit 1
		rescue Config::FileNotExistsException
			# not valid
			STDERR << "#{filename.colorize(:red)} does not exists!\n"
			exit 1
		rescue
			# not valid
			STDERR << "#{filename.colorize(:red)} error!\n"
			exit 1
		end
		config
	end

	def self.load_project? ( filename : String ) : Config::YAML_Project
		begin
			project = Config.load_project filename
		rescue Errno
			STDERR << "You don't have permission for #{filename.colorize(:red)}!\n"
			exit 1
		rescue YAML::ParseException
			# not valid
			STDERR << "#{filename.colorize(:red)} is not valid!\n"
			exit 1
		rescue Config::FileNotExistsException
			# not valid
			STDERR << "#{filename.colorize(:red)} does not exists!\n"
			exit 1
		rescue
			# not valid
			STDERR << "#{filename.colorize(:red)} error!\n"
			exit 1
		end
	end
end
