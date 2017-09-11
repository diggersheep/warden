require "yaml"
require "colorize"

# TODO:
#	- add custom substitutions
#		* sting literal (simple)
#		* sub-substitution with height limit (complex)

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

	# mapping for custom substitutions
	class YAML_sub
		YAML.mapping(
			key:   String,
			value: String
		)
	end

	# mapping of main config file
	class YAML_Config
		YAML.mapping(
			target: String,
			max_substitution_layer: {
				type: UInt32,
				key: "max-substitution-layer"
			},
			delay:  UInt32,
			timeout: UInt32,
			sub: {
				type: Array(YAML_sub),
				nilable: true
			},
			precommand: Array( YAML_Config_Command )
		)
	end
	class YAML_Config_Command
		YAML.mapping(
			files: {
				type: String,
				setter: false
			},
			run: {
				type: String,
				default: "",
				setter: false
			},
			git: {
				type: String,
				default: "none",
				setter: false
			},
			timeout: {
				type: UInt32,
				default: 0_u32,
				setter: false
			}
		)
	end

	# mapping of project config file
	class YAML_Project
		YAML.mapping(
			timeout: {
				type: UInt32,
				default: 0_u32
			},
			delay: {
				type: UInt32,
				default: 0_u32
			},
			sub: {
				type: Array(YAML_sub),
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


		if conf.delay < Warden::MIN_DELAY
			conf.delay = Warden::MIN_DELAY
		end
		if conf.timeout < Warden::MIN_TIMEOUT
			conf.timeout = Warden::MIN_TIMEOUT
		end


		layer = conf.max_substitution_layer
		if layer < Warden::MIN_SUB_LAYER
			layer = Warden::MIN_SUB_LAYER
		end
		if layer > Warden::MAX_SUB_LAYER
			layer = Warden::MAX_SUB_LAYER
		end
		conf.max_substitution_layer = layer

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
