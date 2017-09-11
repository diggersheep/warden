require "colorize"

module Warden
    class Generator
        @config  : Config::YAML_Config

        def initialize ( @config )
            project = "watch:\n"

            msg = [] of String

            data = ""

			# seach with 
            @config.precommand.each do |watcher|
                if Dir.glob(watcher.files).size > 0
                    msg << watcher.files

                    data += "\n"
                    data += "  - files: #{watcher.files}\n"
                    if watcher.run.size > 0
                        data += "    run: \"#{watcher.run}\"\n"
                    end
                    if watcher.git.size > 0
                        data += "    git: #{watcher.git}\n"
                    end
                    if watcher.timeout > 0_u32
                        data += "    timeout: #{watcher.timeout}"
                    end
                end
            end
            
            if data == ""
                project += void_project
            else
                project += data
            end

            unless File.file? config.target
                puts "The Warden is watching is your have some files to monitor".colorize(:cyan)
                if msg.empty?
                    puts "#{"Warden :".colorize(:cyan)} #{"I don't find any specific file! But I can watch others for you :)".colorize(:light_cyan)}"
                else
                    puts "#{"Warden :".colorize(:cyan)} #{"I found some specific files for you! :)".colorize(:light_cyan)}"
                    msg.each { |s| puts "           - #{s}".colorize(:light_cyan) }
                end
                File.write config.target, project
            else
                puts "#{config.target.colorize(:yellow)} already exists!"
                exit 0
            end
        end
        
        private def void_project
            s  = "  - files: ./**/*\n"
            s
        end
    end
end

#Warden::Generator.new config
