# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class Pia
  include Cinch::Plugin

  match /pia (.+)/
  
  def execute(m, query)
    m.reply('Pia!<(=ｏ ‵-′)ノ☆' + query)
  end
end