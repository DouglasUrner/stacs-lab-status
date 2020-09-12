require "parallel"
require "sinatra"
require "zache"

JH105_MACHINES = File.read("jh105.txt").split("\n")
JH110_MACHINES = File.read("jh110.txt").split("\n")
JC035_MACHINES = File.read("jc035.txt").split("\n")

def get_status(hostnames)
  Parallel.map(hostnames, in_threads: 16) do |m|
    status = `ssh -o ConnectTimeout=1 #{m} ruby /cs/home/gbs3/Documents/lab_status/status_check.rb`
    status = if status == ""
      :down
    else
      status.to_sym
    end
    [m, status]
  end
end

set :port, 22623

cache = Zache.new

get "/labs" do
  jh105 = cache.get(:jh105, lifetime: 60) { get_status(JH105_MACHINES) }
  jh110 = cache.get(:jh110, lifetime: 60) { get_status(JH110_MACHINES) }
  jc035 = cache.get(:jc035, lifetime: 60) { get_status(JC035_MACHINES) }
  erb :machines, locals: {jh105: jh105, jh110: jh110, jc035: jc035}
end
