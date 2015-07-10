# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'drb'
require 'telegram_bot'

module Cinch
  class TelegramSync
    attr_reader :tgbot
    def initialize(ircbot, token)
      @ircbot = ircbot
      @tgbot = TelegramBot.new token: token
      p "Cinch::TelegramSync initialized"
    end
    def start
      @tgbot.get_updates(fail_sliently: true) do |message|
        if ::TGSYNC_GROUPS.value? message.chat.id
            @bot.synchronize(:tgsync) { Target.new(::TGSYNC_GROUPS.invert[message.chat.id], @bot).msg("[#{message.user.first_name} #{message.user.last_name}] #{message.text}") }
        end
      end
    end
  end
end