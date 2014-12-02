#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

require 'ruby-audio'
require 'optparse'

class SilenceSeeker

  attr_accessor :silence_limit
  attr_accessor :silence_length

  def initialize
    @silence_limit = 0.02
    @silence_length = 0.5
  end

  def seek(input)

    @frames = input.info.frames
    @rate = input.info.samplerate
    @channels = input.info.channels
    @samples = @rate * 60
    @silence_samples = @silence_length * @rate

    @input_samples = 0

    buf = RubyAudio::Buffer.new("float", @samples, input.info.channels)

    past_time = 0    #seconds
    print '0 '

    while input.read(buf) != 0

      @input_samples += buf.real_size

      pos = 0

      while pos < buf.real_size
        silence_start, silence_length = find_silence(buf, pos)
        print past_time + silence_start / @rate, "\n", past_time + (silence_start + silence_length) / @rate, " " if !silence_start.nil?

        if !silence_start.nil?
          pos = silence_start + silence_length
        else
          # No silence found
          pos = buf.real_size
        end
      end

      past_time += 60

    end

    print @frames / @rate

  end

  def find_silence(buf, position)
    silence_start = -1
    silence_length = 0

    while position < buf.real_size
      if silence?(buf[position])
        if silence_start < 0
          silence_start = position
        end
        silence_length += 1
      else
        if silence_length > @silence_samples
          return silence_start, silence_length
        else
          silence_start = -1
          silence_length = 0
        end
      end
      position += 1
    end

    if silence_length > @silence_samples
      return silence_start, silence_length
    else
      return nil, nil
    end
  end

  def silence?(sample)
    sample.all? { |s| s < @silence_limit }
  end

end

if $0 == __FILE__

  seeker = SilenceSeeker.new

  opts = OptionParser.new do |opts|
    opts.banner = "Usage:  ruby silence-seeker.rb [options] <input.wav>"
    opts.separator ""

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end

    opts.on("--silence LIMIT", Float, "Sample values below LIMIT are considered silence (default #{seeker.silence_limit})") do |limit|
      seeker.silence_limit = limit
    end

    opts.on("--length LENGTH", Float, "Silent gaps longer than LENGTH are modified (default #{seeker.silence_length} s)") do |length|
      seeker.silence_length = length.to_f
    end

    opts.separator ""
  end
  opts.parse!

  if ARGV.size != 1
    puts opts
    exit 1
  end

  input = RubyAudio::Sound.open(ARGV[0])
  seeker.seek(input)
  input.close

end
