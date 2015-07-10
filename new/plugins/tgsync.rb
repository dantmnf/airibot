# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class TelegramSyncPlugin
  include Cinch::Plugin
  listen_to :message, method: :on_message
  def on_message(m)
    return unless $tgsync
    tgbot = $tgsync.tgbot
    nick = m.user.nick
    text = "[#{nick}] #{m.message}"
    tgchat = ::TelegramBot::Channel.new
    tgchat.id = -14381522
    tgmsg = ::TelegramBot::OutMessage.new
    tgmsg.chat = tgchat
    tgmsg.text = text
    tgbot.send_message tgmsg
  end
end
