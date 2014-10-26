# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class Pia
  include Cinch::Plugin

  match /pia (.+)/
  
  def execute(m, query)
    return if $antiflood.log_check_and_ban m
    m.reply('Pia!<(=ｏ ‵-′)ノ☆' + query)
  end
end