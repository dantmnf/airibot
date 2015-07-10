# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

require_relative 'lib/console'
require_relative 'lib/antiflood'
require_relative 'lib/telegram'
require_relative 'plugins/sm'
require_relative 'plugins/pia'
require_relative 'plugins/rollbed'
require_relative 'plugins/webtitle'
require_relative 'plugins/eval.rb'
require_relative 'plugins/bf'
require_relative 'plugins/ip'
require_relative 'plugins/html_parser'
require_relative 'plugins/opbot'
require_relative 'plugins/evaljs'

require_relative 'plugins/tgsync'

CFGFILE = 'config.rb'

$antiflood = AntiFlood.new
bot = Cinch::Bot.new do
  configure do |c|
    begin
      eval File.read(CFGFILE) # example contents in this file is in rescue...end below
    rescue
p $!
      c.nick = 'Airi_new'
      c.user = 'Airi'
      c.realname = '新しいアイリ'
      c.server = "chat.freenode.net"
      c.port = 6697
      c.ssl.use = true
      c.channels = ["##Orz"]
      c.plugins.prefix = /^-/
    end
    c.plugins.plugins = [TelegramSyncPlugin]
  end
  #loggers.level = :log

#  on :ctcp do |m|
#    if m.ctcp_message.upcase == 'VERSION'
#      m.ctcp_reply 'VERSION Airi_new by dantmnf'
#    end
#  end

end

Thread.new do
  Cinch::Console.new(bot).attach
end
Thread.new do
    p 'starting tgsync'
    $tgsync = Cinch::TelegramSync.new(bot, TELEGRAM_TOKEN)
    #bot.instance_variable_set '@tgbot', tgbot
    p 'invoking tgsync.start'
    $tgsync.start
end
bot.start
