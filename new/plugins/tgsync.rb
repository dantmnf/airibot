# encoding: UTF-8
require 'bundler/setup'
require 'cinch'

class TelegramSyncPlugin
  include Cinch::Plugin

  listen_to :message, method: :on_message
  def on_message(m)
    return unless $tgsync
    return unless ::TGSYNC_GROUPS.key?(m.channel.name)
    tgbot = $tgsync.tgbot
    nick = m.user.nick
    text = "[#{nick}] #{m.message}"
    tgchat = ::TelegramBot::Channel.new
    tgchat.id = ::TGSYNC_GROUPS[m.channel.name]
    tgmsg = ::TelegramBot::OutMessage.new
    tgmsg.chat = tgchat
    tgmsg.text = text
    tgbot.send_message tgmsg
  end
end
