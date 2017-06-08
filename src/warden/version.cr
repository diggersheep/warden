class Crystal::Macro::ArrayLiteral
  def reverse : ArrayLiteral
    
  end
end

module Warden
  VERSION = "0.0.3"
  {% if :linux %} # linux / OSX
    RELEASE_DATE = {{ `date +'%Y-%H-%d'`.chomp.stringify }}
  {% else %} # windows
    RELEASE_DATE = {{ `echo %date:~6,4%-%date:~3,2%-%date:~0,2%`.chomp.stringify }}
  {% end%}
end