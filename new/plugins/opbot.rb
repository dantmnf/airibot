# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class OpBot
  include Cinch::Plugin

  match /voice( .+)?/
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    if query
      nick = query.strip
    else
      nick = m.user.nick
    end
    m.channel.voice nick
  end

  match /devoice( .+)?/, method: :devoice
  def devoice(m, query)
    return unless $antiflood.log_check_and_ban m
    if query
      nick = query.strip
    else
      nick = m.user.nick
    end
    m.channel.devoice nick
  end
end
