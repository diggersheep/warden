require "file_utils"
require "colorize"

module Warden
	class Watcher
		@config  : Config::YAML_Config
		@project : Config::YAML_Project

		@added_files   : Array(String)
		@changed_files : Array(String)
		@removed_files : Array(String)

		@archive : Archive

		@files : Array(Hash(String, String | Time))

		def initialize ( @config, @project )
			@added_files   = [] of String
			@changed_files = [] of String
			@removed_files = [] of String

			@archive = Archive.new

			@files = [] of Hash(String, String | Time)

			@project.watch.each do |watcher|
				Dir.glob( watcher.files ).each do |file|
					if File.file? file
						begin
							@files << {
								"file"  => file,
								"run"   => sub_run(file, watcher.run),
								"git"   => watcher.git,
								"mtime" => File::Stat.new(file).mtime
							}
						rescue #Errno
						end
					end
				end
			end

			puts sub_archive
		end

		# subsitutions for archive name
		def sub_archive
			name = @config.archive.name

			dirname = FileUtils.pwd
			if dirname.split(File::SEPARATOR).size > 0
				dirname = dirname.split(File::SEPARATOR)[-1]
			else
				dirname = ""
			end

			name = name.sub "\#{dirname}", dirname
			name = name.sub "\#{iter}", @archive.iter

			name + '.' + @config.archive.format
		end

		# subsitutions for git commit auto messgae
		def sub_git_msg
			git = @config.git_auto_commit
			if git.includes? "\#{git-auto}"
				str = ""

				if @added_files.size > 0
					str += "Added files   : "
					(0...@added_files.size).each do |i|
						if i > 0
							str += ", "
						end
						str += @added_files[i]
					end
				end

				if @changed_files.size > 0
					str += "\nChanged files : "
					(0...@changed_files.size).each do |i|
						if i > 0
							str += ", "
						end
						str += @changed_files[i]
					end
				end

				if @removed_files.size > 0
					str += "\nRemoved files : "
					(0...@removed_files.size).each do |i|
						if i > 0
							str += ", "
						end
						str += @removed_files[i]
					end
				end

				git.sub "\#{git-auto}", str
			else
				git
			end
		end

		# subsitutions for running commands
		def sub_run ( filename : String, cmd : String )
			cmd = cmd.sub "\#\{\}", ""
			cmd = cmd.sub "\#\{file\}", filename
			cmd = cmd.sub "\#\{path\}", (File.dirname(filename) + File::SEPARATOR)
			cmd = cmd.sub "\#\{basename\}", (File.basename(filename)[0, File.basename(filename).size - File.extname(filename).size])
			cmd = cmd.sub "\#\{extname\}", File.extname(filename)
			cmd = cmd.sub "\#\{pwd\}", FileUtils.pwd
			cmd = cmd.sub "\#\{cwd\}", FileUtils.pwd
			cmd = cmd.sub "\#\{dirname\}", FileUtils.pwd.split(File::SEPARATOR)[-1]
			cmd = cmd.gsub /\#\{*\}/, filename
			cmd
		end
	end
end

filename = "config.yml"

# CONFIG
config = Config.load_config? filename
# PROJECT
project = Config.load_project config.target

# WATCHER
watcher = Warden::Watcher.new config, project
