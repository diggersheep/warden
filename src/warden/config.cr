require "yaml"

module Config

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
			archive: YAML_Config_Archive,
			precommand: Array( YAML_Config_Command )
		)
	end
	class YAML_Config_Archive
		YAML.mapping(
			name:   String,
			format: String
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
				key:  "auto-commit-message",
				type: String
			},
			recursive_path: {
				key: "recursive-path",
				type: Bool
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
	def self.load_config ( filename : String ) : (YAML_Config | Nil)

		data = "" # future file data

		# load data
		if File.file? filename
			tmp = File.read filename
			unless tmp.nil?
				data = tmp.as String
			else
				return nil
			end
		else
			return nil
		end

		# parse yaml file (not handle exception)
		conf = YAML_Config.from_yaml data
	
		unless conf.nil?
			conf.precommand.each do |e|
				unless check_git e.git
					return nil
				end
			end
		end
		conf
	end

	def self.load_project ( filename : String ) : (Config::YAML_Project | Nil)
		data = "" # future file data

		#load data
		if File.file? filename
			tmp = File.read filename
			unless tmp.nil?
				data = tmp.as String
			else
				return nil
			end
		else
			return nil
		end

		# parse yaml file (not handle exception)
		conf = YAML_Project.from_yaml data
		unless conf.nil?
			conf.watch.each do |e|
				unless check_git e.git
					return nil
				end
			end
		end
	end
end


Config.load_project ".guardian++.yml"
