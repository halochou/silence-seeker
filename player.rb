#!/usr/bin/env ruby

require 'rubygems'
require 'curses'

# require_relative '../lib/audite'
require 'audite'

class AuditePlayer < Audite
  attr_accessor :points
  attr_accessor :current_pos
end


player = AuditePlayer.new #Audite.new

points = Array.new
player.current_pos = 0

player.points = points

File.readlines('checkpoints').each do |line|
  start, stop = line.split
  points.push({ :time_start => start.to_i, :time_stop => stop.to_i })
end

player.events.on(:complete) do
  exit
end

player.events.on(:position_change) do |pos|
  if player.position.ceil > player.points[player.current_pos][:time_stop] + 1
    player.toggle
  end

  p = (player.tell / player.length * Curses.cols).ceil
  l = player.level
  Curses.setpos(0, 0)
  Curses.addstr("playing #{ARGV[0]}    #{player.position.ceil} seconds of #{player.length_in_seconds.ceil} total")
  Curses.setpos(1, 0)
  Curses.addstr("#" * p + " " * (Curses.cols - p))
  Curses.setpos(2, 0)
  Curses.addstr("Playing...") if player.active
  Curses.addstr("Paused    ") if !player.active
  Curses.setpos(3, 0)
  Curses.addstr("Level: #{l}")
  Curses.refresh
end

Curses.init_screen
Curses.noecho
Curses.stdscr.keypad(true)
Curses.clear

player.load(ARGV[0])
player.start_stream

while c = Curses.getch
  case c
  when 'b' #Curses::KEY_LEFT
    player.current_pos -= 1
    player.seek(player.points[player.current_pos][:time_start])
    player.toggle if !player.active
  when 'n' #Curses::KEY_RIGHT
    player.current_pos += 1
    player.seek(player.points[player.current_pos][:time_start])
    player.toggle if !player.active
  when ' '
    player.seek(player.points[player.current_pos][:time_start])
    player.toggle if !player.active
  when 'p'
    player.toogle
  end
end
