require 'audite'

player = Audite.new

player.events.on(:complete) do
  puts "COMPLETE"
  exit
end

player.events.on(:position_change) do |pos|
  puts "POSITION: #{pos} seconds  level #{player.level}"
end

player.load('sample.mp3')
player.start_stream
#player.forward(20)
