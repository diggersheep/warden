require "colorize"

module Warden
    class Generator
        @config  : Config::YAML_Config
        @project : String

        def initialize ( @config )
            @project =  "auto-commit-message: \"\#\{git-auto\}\"\n"
            @project += "watch:\n"

            data = ""
            @config.precommand.each do |watcher|
                if Dir.glob(watcher.files).size > 0
                    puts watcher.files
                    data += "\n"
                    data += "  - files: #{watcher.files}\n"
                    data += "    run: \"#{watcher.run}\"\n"
                    data += "    git: #{watcher.git}\n"
                end
            end
            
            if data == ""
                void_project
            else
                @project += data
            end

            unless File.file? config.target
                File.write config.target, @project
            else
                puts "#{config.target.colorize(:yellow)} already exists!"
                exit 0
            end
        end
        
        private def void_project
            @project += "  - files: ./**/*\n"
            @project += "    run: echo \"\#\{file\} is changed\"\n"
            @project += "    git: none\n"
        end
    end
end

#Warden::Generator.new config
