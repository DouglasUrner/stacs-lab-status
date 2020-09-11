require "parallel"
require "sinatra"

JH105_MACHINES = File.read("jh105.txt").split("\n")
JH110_MACHINES = File.read("jh110.txt").split("\n")
JC035_MACHINES = File.read("jc035.txt").split("\n")

def get_status(hostnames)
  Parallel.map(hostnames, in_threads: 16) do |m|
    status = `ssh -o ConnectTimeout=1 #{m} loginctl list-sessions --no-legend`
    session_lines = status.split("\n")
    ssh_sessions = session_lines.find_all { |l| !l.include? "seat0" }
    user_sessions = session_lines.find_all { |l| l.include?("seat0") && !l.include?(" gdm ") }
    status = if status == ""
      :down
    elsif user_sessions.length > 0
      :in_use
    elsif ssh_sessions.length > 1 # we connect via ssh, so always at least 1 here
      :ssh
    else
      :open
    end
    [m, status]
  end
end

set :port, 22623

get "/labs" do
  jh105 = get_status(JH105_MACHINES)
  jh110 = get_status(JH110_MACHINES)
  jc035 = get_status(JC035_MACHINES)
  erb :machines, locals: {jh105: jh105, jh110: jh110, jc035: jc035}
end
