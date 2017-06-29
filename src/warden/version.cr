module Warden
  # 0.1.3
  #   -> remove obsolete archive config (auto archive feature)
  # 0.1.2
  #   -> fix timeout priority  (CLI  option > .warden.yml)
  # 0.1.1
  #   -> print nothing if "run" parameter in .warden.yml is empty
  # 0.1.0
  #   -> linux ready
  #   -> can be un/install
  #   -> dynamic .warden.yml load
  #   -> don't support yet "git commit" feature
  VERSION = "0.1.3"

  # format YYYY-MM-DD
  RELEASE_DATE = {{ `date +'%Y-%H-%d'`.chomp.stringify }}

  def self.print_version
    puts "#{"Warden".colorize(:cyan)} v#{VERSION} #{"(#{RELEASE_DATE})".colorize(:light_gray)}"
  end
end