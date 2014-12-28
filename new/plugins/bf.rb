# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

require_relative '../lib/brainfuck'

class BFPlugin
  include Cinch::Plugin

  match /bf (.+)/
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    itpr = BrainFuck.new
    itpr.compile query
    result = itpr.run
    if result.length > 140
      result = result[0..137] + '...'
    end
    m.reply(result.empty? ? 'no output' : result, true)
  end
end
