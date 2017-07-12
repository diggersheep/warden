module Config
    class Sub

        @subs : Array(Config::YAML_sub)

        def initialize ( subs : Array(Config::YAML_sub) | Nil )
            if subs.nil?
                @subs = [] of Config::YAML_sub
            else
                @subs = subs
            end

        end

        def multi_sub
            @subs.each do |subs|
                @subs.each do |sub|
                    if subs.key != sub.key
                        match = "\#{#{sub.key}}"
                        subs.value = subs.value.gsub /#{match}/, sub.value
                    end
                end
            end
        end

        # make subsitutions
        def sub ( str : String )
            @subs.each do |sub|
                match = "\#{#{sub.key}}"
                str = str.gsub /#{match}/, sub.value
            end
            str
        end
    end
end