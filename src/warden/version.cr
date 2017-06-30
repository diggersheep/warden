module Warden
  VERSION = "0.1.3"

  # format YYYY-MM-DD
  RELEASE_DATE = {{ `date +'%Y-%H-%d'`.chomp.stringify }}

  def self.print_version
    puts "#{"Warden".colorize(:cyan)} v#{VERSION} #{"(#{RELEASE_DATE})".colorize(:light_gray)}"
  end
end