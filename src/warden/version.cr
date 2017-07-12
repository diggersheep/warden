module Warden
  VERSION = "0.2.0"

  # format YYYY-MM-DD
  RELEASE_DATE = {{ `date +'%Y-%m-%d'`.chomp.stringify }}

  def self.print_version
    puts "#{"Warden".colorize(:cyan)} v#{VERSION} #{"(#{RELEASE_DATE})".colorize(:light_gray)}"
  end
end
