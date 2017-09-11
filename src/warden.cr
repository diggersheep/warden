require "./warden/*"
require "./option_parser"


class OptionParser
    # override of appendd_flag method for colorized print
    # exactly like original but colorized
    private def append_flag(flag, description)
        if flag.size >= 33
            @flags << "    #{flag.colorize(:light_gray)}\n#{" " * 37}#{description}"
        else
            @flags << "    #{flag.colorize(:light_gray)}#{" " * (33 - flag.size)}#{description}"
        end
    end
end

filename = "config.yml"

t_option = false
d_option = false

release = false
# CONFIG - ugly but for the moment, it's work, I search a prettier and more generic method ;)
{% if `cat RELEASE`.chomp.stringify.size != 0 %}
	filename = "/usr/share/warden/#{filename}"
    release = true
{% end %}

config = Config.load_config? filename

if ARGV[0]?
    OptionParser.parse! do |opt|
        opt.banner = "help : "

        # VERSSION
        opt.on "-v", "--version", "Show the version" do
            Warden.print_version
            exit
        end

        # HELP
        opt.on "-h", "--help", "Show this help" do
            puts opt
            exit
        end

        # DELAY
        opt.on "-d DELAY", "--delay=DELAY", "Delay in ms between two folder check" do |delay|
            begin
                config.delay = delay.to_u32
            rescue
                puts opt
                exit 1
            end
        end

        # TIMEOUT
        opt.on "-t TIMEOUT", "--timeout=TIMEOUT", "Timeout in ms for command " do |timeout|
            begin
                unless timeout.to_u32 < 250_u32
                    config.timeout = timeout.to_u32
                else
                    config.timeout = 250_u32
                end
                t_option = true
            rescue
                puts opt
                exit 1
            end
        end

        # UNINSTALL
        opt.on "--uninstall", "uninstall this program, but ... You don't need to use it :P" do
            
            puts "Are you sure to uninstall this program? (yes/NO)"
            ok = gets()
            unless ok.nil?
                unless ok.as(String).downcase == "yes"
                    puts "The answer is no!"
                    puts "Good choice ;)"
                    exit 0
                end
            end

            if release
                puts "uninstallation:".colorize
                begin
                    FileUtils.rm Dir.glob("/usr/share/warden/*")
                    puts "  - deletion files into the directory #{"/usr/share/warden/".colorize(:yellow)}"
                rescue Errno
                    puts "#{"/usr/bin/warden/*".colorize(:red)} don't want to be deleted - maybe a #{"'sudo'".colorize(:light_gray)} can resolve this problem"
                    exit 1
                end

                begin
                    if Dir.exists? "/usr/share/warden"
                        Dir.rmdir "/usr/share/warden"
                    end 

                    puts "  - deletion of the directory #{"/usr/share/warden/".colorize(:yellow)}"
                rescue Errno
                    puts "#{"/usr/bin/warden/".colorize(:red)} folder don't want to be deleted - maybe a #{"'sudo'".colorize(:light_gray)} can resolve this problem"
                    exit 1
                end

                # BINARY
                begin
                    if File.exists? "/usr/bin/warden"
                       File.delete "/usr/bin/warden"
                    else
                        puts "déja del"
                    end
                    puts "  - deletion of the binary #{"/usr/bin/warden".colorize(:yellow)}"
                rescue Errno

                    puts "#{"/usr/bin/warden".colorize(:red)} don't want to be deleted - maybe a #{"'sudo'".colorize(:light_gray)} can resolve this problem"
                    exit 1
                end
                puts "Uninstallation finished".colorize(:green)
                puts
                puts "Goodbye :)"
            else
                puts "You are not in a release, you don't have any files installed ;)".colorize(:cyan)
            end
            exit 0
        end

        # INIT
        opt.on "-i", "--init", "Generate '#{config.target}' (project file), automatically based on '#{filename}' main config file" do
            Warden::Generator.new config
            exit
        end

        # INVALID
        opt.invalid_option do
            puts opt
            exit 1
        end
        # MISSING
        opt.missing_option do
            puts opt
            exit 1
        end
    end
end

# PROJECT CONFIG FILE
project = Config.load_project? config.target

# load project timeout
unless  project.timeout == 0_u32 || t_option
    t = project.timeout.as(UInt32) < 125_u32 ? 125_u32 : project.timeout.as(UInt32)
    config.timeout = t
end
# load project delay
unless project.delay == 0_u32 || t_option
    d = project.delay.as(UInt32) < 250_u32 ? 250_u32 : project.delay.as(UInt32)
    config.delay = d
end

# WATCHER
watcher = Warden::Watcher.new config, project
watcher.run
