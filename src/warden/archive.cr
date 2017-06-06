module Warden
    class Archive
        @iter : UInt32
        @name : String

        getter iter
        getter name

        setter name

        def initialize 
            @iter = 1_u32
            @name = ""
        end

        def write
            if @name.size > 0
                @iter += 1
            end
        end
    end
end