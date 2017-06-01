module Guardian
    class Inspector
        @dirname : String
        @dirs : Array(String)
        @new_dirs : Array(String)

        getter dirs

        def initialize ( @dirname )
            @dirs     = [] of String
            @new_dirs = [] of String

            analyse @dirname, @dirs
        end

        private def analyse ( d : String, dirs : Array(String) )
            while d[-1] == File::SEPARATOR && d.size > 1
                d = d[0, -1]
            end
            Dir.entries(d).each do |file|
	            if file != "." && file != ".."
    	            if File.directory? "#{d}#{File::SEPARATOR}#{file}"
                    	analyse "#{d}#{File::SEPARATOR}#{file}", dirs
                	else
                   		dirs << "#{d}#{File::SEPARATOR}#{file}"
                	end
            	end
			end
        end

		def diff
			analyse @dirname, @new_dirs
			
			files = {
				deleted_files: @dirs - @new_dirs,
				new_files: @new_dirs - @dirs
			}
			@dirs = @new_dirs
			@new_dirs = [] of String

			puts @dirs.size
			puts @new_dirs.size

			return files
		end
    end
end

#i = Guardian::Inspector.new "."
#i.dirs.each { |e| puts e }

