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
    text = format_message m
    tgchat = ::TelegramBot::Channel.new
    tgchat.id = ::TGSYNC_GROUPS[m.channel.name]
    tgmsg = ::TelegramBot::OutMessage.new
    tgmsg.chat = tgchat
    tgmsg.text = text
    tgbot.send_message tgmsg
  end
  def format_message(message)
    actmsg =  message.action_message.to_s.strip
    if actmsg.empty?
      "[#{message.user.nick}] #{message.message}"
    else
      "\u2b50 #{message.user.nick} #{actmsg}"
    end
  end
end
