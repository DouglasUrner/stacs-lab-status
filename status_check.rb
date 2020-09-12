# This runs on the lab clients to determine the machine's status.

sessions_text = `loginctl list-sessions --no-legend`
session_ids = sessions_text.split("\n").map do |line|
  line =~ /^ *(\d+).*$/
  $1
end

sessions = session_ids.map do |id|
  session_data = `loginctl show-session #{id}`
  session = Hash[session_data.split("\n").map { |line| line.split("=") }]
end

ssh_sessions = sessions.find_all { |sess| sess["Remote"] == "yes" }
desktop_sessions = sessions.find_all { |sess| sess["Remote"] == "no" && sess['Seat'] == "seat0" && sess['Name'] != 'gdm' }

active_desktop_sessions = desktop_sessions.find_all { |sess| sess["Active"] == "yes" && sess["LockedHint"] == "no" && sess["IdleHint"] == "no" }

status = if active_desktop_sessions.length > 0
  :in_use
elsif ssh_sessions.length > 1 # we connect via ssh, so always at least 1 here
  :ssh
else
  :open
end

puts status