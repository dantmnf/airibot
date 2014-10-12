# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

require_relative 'lib/console'
require_relative 'plugins/sm'
require_relative 'plugins/pia'
require_relative 'plugins/rollbed'
require_relative 'plugins/webtitle'
require_relative 'plugins/eval.rb'

CFGFILE = 'config.rb'

bot = Cinch::Bot.new do
  configure do |c|
    begin
      eval File.read(CFGFILE) # example contents in this file is in rescue...end below
    rescue
      c.nick = 'Airi_new'
      c.user = 'Airi'
      c.realname = '新しいアイリ'
      c.server = "chat.freenode.net"
      c.port = 6697
      c.ssl.use = true
      c.channels = ["#linuxba"]
      c.plugins.prefix = /^-/
    end
    c.plugins.plugins = [SM, Pia, WebTitle, Rollbed, EvalRb]
  end
  #loggers.level = :log
end

Thread.new do
  Cinch::Console.new(bot).attach
end

bot.start
