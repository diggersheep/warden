module Warden
  VERSION = "0.0.4"

  # format YYYY-MM-DD
  {% if flag?(:windows) %}
    RELEASE_DATE = {{ `echo %date:~6,4%-%date:~3,2%-%date:~0,2%`.chomp.stringify }}
  {% else %}
    RELEASE_DATE = {{ `date +'%Y-%H-%d'`.chomp.stringify }}
  {% end%}

  def self.print_version
    puts "#{"Warden".colorize(:cyan)} v#{VERSION} #{"(#{RELEASE_DATE})".colorize(:light_gray)}"
  end
end