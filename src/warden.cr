require "./warden/*"
require "./option_parser"

filename = "config.yml"


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

# CONFIG
config = Config.load_config? filename

# PROJECT CONFIG FILE
project = Config.load_project? config.target

# load project timeout
unless project.timeout.nil?
    config.timeout = project.timeout.as UInt32
end

banner =  "#{"usage :".colorize(:dark_gray)} #{"warden".colorize(:green)} "
banner += "#{"[-v|--version]".colorize(:light_green)}"
banner += "#{"[-h|--help]".colorize(:light_green)}"


if ARGV[0]?
    OptionParser.parse! do |opt|
        #opt.banner = banner
        opt.banner = "help : "
        opt.on "-v", "--version", "Show the version" do
            Warden.print_version
            exit
        end
        opt.on "-h", "--help", "Show this help" do
            puts opt
            exit
        end

        opt.on "-h", "--help", "Show this help" do
            puts opt
            exit
        end

        opt.on "-d DELAY", "--delay=DELAY", "Show this help" do |delay|
            begin
                config.delay = delay.to_u32
            rescue
                puts opt
                exit 1
            end
        end

        opt.on "-t TIMEOUT", "--timeout=TIMEOUT", "Timeout in ms for command " do |timeout|
            begin
                unless timeout.to_u32 < 250_u32
                    config.timeout = timeout.to_u32
                else
                    config.timeout = 250_u32
                end
            rescue
                puts opt
                exit 1
            end
        end

        opt.on "-i", "--init", "Generate " do
            Warden::Generator.new config
            exit
        end

        opt.invalid_option do
            puts opt
            exit 1
        end
        opt.missing_option do
            puts opt
            exit 1
        end
    end
end

# WATCHER
watcher = Warden::Watcher.new config, project
watcher.run