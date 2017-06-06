require "file_utils"
require "colorize"


# TODO
#   - Fix deleted_files()

module Warden
	class Watcher
		@config  : Config::YAML_Config
		@project : Config::YAML_Project

		@added_files   : Array(String)
		@changed_files : Array(String)
		@removed_files : Array(String)

		@archive : Archive

		@files : Array(NamedTuple(file: String, run: String, git: String, mtime: Time))

		def initialize ( @config, @project )
			@added_files   = [] of String
			@changed_files = [] of String
			@removed_files = [] of String

			@archive = Archive.new

			@files = [] of NamedTuple(file: String, run: String, git: String, mtime: Time)
			if config.delay < 250_u32
				config.delay = 250_u32
			end

			@project.watch.each do |watcher|
				Dir.glob( watcher.files ).each do |file|
					if File.file? file
						begin
							tmp = {
								file:  file,
								run:   sub_run(file, watcher.run),
								git:   watcher.git,
								mtime: File::Stat.new(file).mtime
							}
							@files << tmp
						rescue #Errno
							# do nothing
						end
					end
				end
			end
			# ⚝ = U+269D unicode for outlined white star
			# ♖ = U+2656 unicode for white chess rook
			# ♜ = U+265C unicode for black chess rook
			puts "\u{265C} The warden is closely watching your files!".colorize(:light_blue) 
		end

		private def is_new? ( filename : String ) : Bool
			@files.each do |file|
				if file[:file] == filename
					return false
				end
			end
			return true
		end

		private def is_changed? ( f : NamedTuple(file: String, run: String, git: String, mtime: Time) ) : Bool
			@files.each do |file|
				if (file[:file] == f[:file]) && (f[:mtime] != file[:mtime])
					return true
				end
			end
			false
		end

		private def is_in_files_bis ( filename : String, files_bis : Array(NamedTuple(file: String, run: String, git: String, mtime: Time)) )
			@files.each do |file|
				if file[:file] == filename
					return true
				end
			end
			false
		end

		private def deleted_files ( files : Array(NamedTuple(file: String, run: String, git: String, mtime: Time)) )
			tmp = typeof(@files).new

			files.each do |file|
				unless is_in_files_bis file[:file], files
					puts file[:file]
					tmp << file
				end
			end

			tmp
		end

		private def run_cmd ( str_cmd : String )
			puts "#{"$".colorize(:dark_gray)} #{str_cmd.colorize(:light_blue)}"
			cmd = `#{str_cmd}`
			cmd.lines.each do |line|
				puts "#{">".colorize(:dark_gray)}   #{line}"
			end
		end
		private def puts_diff ( filename : String )
			if File.directory? ".git"
				git = `which git`.chomp
				unless git.empty?
					git_stat = `#{git} diff --shortstat -- #{filename}`.split(", ")
					if git_stat.size > 1
						str = git_stat[1,git_stat.size - 1].join(", ").colorize(:yellow)
						puts "  #{"->".colorize(:light_yellow)} #{str}"
#						puts "\\ #{git_stat[1]} #{git_stat[1]}"
					end
				end
			end
		end

		private def run_git ( file : NamedTuple(file: String, run: String, git: String, mtime: Time) )
			case file[:git]
			when "none" #do nothing
			when "add"
				`git add #{file[:file]}`
				puts "  git add #{file[:file]}".colorize(:dark_gray)
				unless @added_files.includes? file[:file]
					@added_files << file[:file]
				end                                      
			when "commit"
#				msg = ""
#				puts "  git commit -m \"#{msg}\""
				@added_files.clear
			when "pull"
				puts "  git pull".colorize(:dark_gray)
				`git pull`
			when "push"
				puts "  git push".colorize(:dark_gray)
				`git push`
			end
		end

		def iter
			new_files     = typeof(@files).new
			changed_files = typeof(@files).new

			files_bis = typeof(@files).new

			@project.watch.each do |watcher|
				Dir.glob watcher.files do |file|
					begin
						tmp = {
							file: file,
							run: sub_run(file, watcher.run),
							git: watcher.git,
							mtime: File::Stat.new(file).mtime
						}
						files_bis << tmp

						if is_new? file
							new_files << tmp
						elsif is_changed? tmp
							changed_files << tmp
						end
					rescue
					end	
				end
			end

			deleted_files(files_bis).each do |file|
				puts "#{"-".colorize(:light_red)} #{"deleted".colorize(:red)} #{file[:file]}"
			end

			new_files.each do |file|
				puts "#{"+".colorize(:light_green)} #{"added".colorize(:green)}   #{file[:file]}"
				run_cmd file[:run]
				run_git file
			end

			# ± = U+00B1 unicode for plus-minus sign
			changed_files.each do |file|
				puts "#{"\u{00B1}".colorize(:light_yellow)} #{"changed".colorize(:yellow)} #{file[:file]}"
				puts_diff file[:file]
				run_cmd file[:run]
				run_git file
			end

			#@added_files.each { |e| puts e }

			@files = files_bis
		end

		# subsitutions for archive name
		private def sub_archive
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
		private def sub_git_msg
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

			else
				git
			end
		end

		# subsitutions for running commands
		private def sub_run ( filename : String, cmd : String )
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

		def run
			loop do
				iter
				sleep @config.delay / 1000.0
			end
		end
	end
end


