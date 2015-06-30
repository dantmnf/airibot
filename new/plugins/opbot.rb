# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class OpBot
  include Cinch::Plugin

  match /voice( .+)?/i
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    if query
      nick = query.strip
    else
      nick = m.user.nick
    end
    m.channel.voice nick unless m.channel.voiced? nick
  end

  match /devoice( .+)?/i, method: :devoice
  def devoice(m, query)
    return unless $antiflood.log_check_and_ban m
    if query
      nick = query.strip
    else
      nick = m.user.nick
    end
    m.channel.devoice nick if m.channel.voiced? nick
  end

  match /cutjj$/i, method: :cutjj
  def cutjj(m)
    m.bot.nick = m.bot.config.nick
  end
end
