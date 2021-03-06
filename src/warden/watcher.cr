require "file_utils"
require "colorize"


# TODO
#   - completed git_run() -> hint: git status --porcelain

module Warden
	class Watcher

		@config  : Config::YAML_Config
		@project : Config::YAML_Project
		@project_mtime : Time | Nil
		@coef = 2_u8

		@timeout : UInt32
		@delay : UInt32

		@added_files   : Array(String) # not used for now
		@changed_files : Array(String) # not used for now
		@removed_files : Array(String) # not used for now

		@files : Array(NamedTuple(file: String, run: String, git: String, timeout: UInt32, mtime: Time))

		@subs : Config::Sub

		def initialize ( @config, @project )
			begin
				@project_mtime = File::Stat.new(@config.target).mtime
			rescue
				@project_mtime = nil
			end

			@subs = Config::Sub.new @project.sub
			(1..@config.max_substitution_layer).each { @subs.multi_sub }

			@timeout = @config.timeout
			@delay   = @config.delay

			@added_files   = [] of String
			@changed_files = [] of String
			@removed_files = [] of String

			@files = [] of NamedTuple(file: String, run: String, git: String, timeout: UInt32, mtime: Time)

			# check for each files in project config
			@project.watch.each do |watcher| # project config
				Dir.glob( watcher.files ).each do |file| # each files
					if File.file? file
						t = watcher.timeout < Warden::MIN_TIMEOUT ? @config.timeout : watcher.timeout

						begin
							tmp = {
								file:  file,
								run:   sub_run(file, watcher.run),
								git:   watcher.git,
								timeout: t,
								mtime: File::Stat.new(file).mtime
							}
							@files << tmp
						rescue # File::Stat can raise Errno
							# do nothing
						end
					end
				end
			end
			


			{% if flag?(:windows) %} # Windows console doesn't support unicode charactrers
				puts "The warden is closely watching your files!".colorize(:cyan)
			{% else %}
				# ♜ = U+265C unicode for black chess rook
				puts "\u{265C} The warden is closely watching your files!".colorize(:cyan) 
			{% end %}
			print_arrow
		end

		# print a simple arrow (greater symbol)
		def print_arrow
			print "> ".colorize(:dark_gray)
		end
		# erase two characters
		def errase_arrow
			print "\r\r"
		end

		# return a boolean
		# false if file already exists in "@files" attrbute
		private def is_new? ( filename : String ) : Bool
			@files.each do |file|
				if file[:file] == filename
					return false
				end
			end
			return true
		end

		# return a boolean
		# true if file already exists on "@files" attrubute and m_time is different
		private def is_changed? ( f : NamedTuple(file: String, run: String, git: String, timeout: UInt32, mtime: Time) ) : Bool
			@files.each do |file|
				if (file[:file] == f[:file]) && (f[:mtime] != file[:mtime])
					return true
				end
			end
			false
		end

		private def deleted? ( filename : String, new_files : Array(NamedTuple(file: String, run: String, git: String, timeout: UInt32, mtime: Time)) )
			# fichier supprimé si le fichier filename
			# n'est pas dans new_files
			
			new_files.each do |file|
				if file[:file] == filename
					return false
				end
			end
			true
		end

		# return an array of all deleted files
		private def deleted_files ( files : Array(NamedTuple(file: String, run: String, git: String, timeout: UInt32, mtime: Time)) )
			tmp = typeof(@files).new

			@files.each do |old_files|
				if deleted? old_files[:file], files
					tmp << old_files
				end
			end

			tmp
		end

		# run the following cmd
		private def run_cmd ( cmd_str : String, timeout : UInt32 ) : Bool
			if cmd_str.size == 0
				return true
			end

			puts "#{"$".colorize(:dark_gray)} #{cmd_str.colorize(:light_gray)}"
			timer = Time.new + (timeout / 1000.0).seconds

			# run cmd on a new processus
			cmd = Process.new cmd_str, shell: true, output: true, input: true, error: true

			# spawn a Fiber who kill the command processus if timer is out
			# implementation with sleep to take less ressources than
			# with a "while" loop
			spawn do
				sleep (timeout / 1000.0)
				unless cmd.terminated?
					cmd.kill Signal::KILL
					puts "    the command take more than #{(@config.timeout/1000.0).round(3)}s and has been #{"killed".colorize(:red)} #{"(SIGKILL)".colorize(:dark_gray)}"
				end
			end

			# wait the end of cmd
			cmd.wait.success?
		end

		# print short git diff (addition et deletion) if it's possible
		private def puts_diff ( filename : String )
			if File.directory? ".git"
				git = `which git`.chomp
				unless git.empty?
					git_stat = `#{git} diff --shortstat -- #{filename}`.split(", ")
					if git_stat.size > 1
						str = git_stat[1,git_stat.size - 1].join(", ").colorize(:yellow)
						puts "  #{"->".colorize(:light_yellow)} #{str}"
					end
				end
			end
		end

		# Run the following git command
		private def run_git ( file : NamedTuple(file: String, run: String, git: String, timeout: UInt32, mtime: Time) )
			case file[:git]
			when "none" #do nothing
			when "add"
				`git add #{file[:file]}`
				puts "  git add #{file[:file]}".colorize(:dark_gray)
				unless @added_files.includes? file[:file]
					@added_files << file[:file]
				end                                
			when "commit"
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

			# check .warden.yml file and reload it if necessary
			begin
				time = File::Stat.new(@config.target).mtime
				if  @project_mtime.nil? || @project_mtime.as(Time) < time
					@project_mtime = time
					@project = Config.load_project? @config.target
					
					# load project timeout or default timeout
					unless @project.timeout == 0_u32
						t = @project.timeout < Warden::MIN_TIMEOUT ? Warden::MIN_TIMEOUT : @project.timeout
						@config.timeout = t
					else
						@config.timeout = @timeout
					end

					# load project delay of default delay
					unless @project.delay == 0_u32
						d = @project.delay < Warden::MIN_DELAY ? Warden::MIN_DELAY : @project.delay
						@config.delay = d
					else
						@config.delay = @delay
					end

					errase_arrow
					puts "#{"\u{00B1}".colorize(:light_yellow)} #{"project file has been updated! (#{@config.target})".colorize(:yellow)}"
					print_arrow
				end
			rescue
				# do nothing, if we can't access to .warden.yml, maybe next could ?
			end

			@project.watch.each do |watcher| # project config
				Dir.glob watcher.files do |file| # each files
					t = watcher.timeout < Warden::MIN_TIMEOUT ? @config.timeout : watcher.timeout
					
					begin
						tmp = {
							file: file,
							run: sub_run(file, watcher.run),
							git: watcher.git,
							timeout: t,
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

			# for each deleted files detected
			deleted_files(files_bis).each do |file|
				errase_arrow
				puts "#{"-".colorize(:light_red)} #{"deleted".colorize(:red)} #{file[:file]}"
				print_arrow
			end

			# for each new files detected
			new_files.each do |file|
				errase_arrow
				puts "#{"+".colorize(:light_green)} #{"added".colorize(:green)}   #{file[:file]}"
				if run_cmd file[:run], file[:timeout]
					run_git file
				end
				print_arrow
			end

			# ± = U+00B1 unicode for plus-minus sign
			# for each changed files detected
			changed_files.each do |file|
				errase_arrow
				puts "#{"\u{00B1}".colorize(:light_yellow)} #{"changed".colorize(:yellow)} #{file[:file]}"
				puts_diff file[:file]
				if run_cmd file[:run], file[:timeout]
					run_git file
				end
				print_arrow
			end

			@files = files_bis
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
			# custom subs
			cmd = @subs.sub cmd

			# static subs
			cmd = cmd.gsub "\#\{\}", ""
			cmd = cmd.gsub "\#\{file\}", filename
			cmd = cmd.gsub "\#\{path\}", (File.dirname(filename) + File::SEPARATOR)
			cmd = cmd.gsub "\#\{basename\}", (File.basename(filename)[0, File.basename(filename).size - File.extname(filename).size])
			cmd = cmd.gsub "\#\{extname\}", File.extname(filename)
			cmd = cmd.gsub "\#\{pwd\}", FileUtils.pwd
			cmd = cmd.gsub "\#\{cwd\}", FileUtils.pwd
			cmd = cmd.gsub "\#\{dirname\}", FileUtils.pwd.split(File::SEPARATOR)[-1]

			# general sub (delete any non-system substitution)
			cmd = cmd.gsub /\#\{*\}/, filename
			
			cmd
		end

		# event loop (run forever)
		def run
			while true
				iter
				sleep @config.delay / 1000.0
			end
		end
	end
end


