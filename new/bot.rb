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
        c.nick = 'Airi_new'
        c.user = 'Airi'
        c.realname = 'the new Airi'
        c.server = "chat.freenode.net"
        c.port = 6697
        c.ssl.use = true
        c.channels = ["##Airi-test"]
        c.plugins.prefix = /^-/
        #::TELEGRAM_TOKEN='xxxxxxxx:xxxxxxxxxxxxxxxxxxxxxxxxxxx__xxxxxx'
        #::TGSYNC_GROUPS = {'##channel' => -1234567}
        
        #c.sasl.username = ''
        #c.sasl.password = ''
    end
    c.plugins.plugins = [SM, Pia, WebTitle, Rollbed, EvalRb, BFPlugin, IPQuery, HTMLParserPlugin, OpBot, EvalJS, TelegramSyncPlugin]
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
    $tgsync = Cinch::TelegramSync.new(bot, ::TELEGRAM_TOKEN)
    $tgsync.start
end
bot.start
