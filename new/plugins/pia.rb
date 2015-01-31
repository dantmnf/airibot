# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class Pia
  include Cinch::Plugin

  match /pia (.+)/
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    m.reply('Pia!<(=ｏ ‵-′)ノ☆' + query)
  end

  match /slap( .+)?/, method: :slap
  def slap(m, query)
    query = query.to_s.strip
    if query.empty?
      query = m.user.nick
    end
    m.action_reply "slaps #{query} around a bit with a large trout"
  end
end
