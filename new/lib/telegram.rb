# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'telegram_bot'

module Cinch
  class TelegramSync
    include Cinch::Helpers
    
    def initialize(ircbot, token)
      @ircbot = bot
      @tgbot = TelegramBot.new token: token
      p "Cinch::TelegramSync initialized"
    end
    
    attr_reader :tgbot
    
    def start
        
        @tgbot.get_updates(fail_sliently: true) do |message|
            if message.chat.id == -14381522
                @bot.synchronize(:tgsync) { Target.new('##Orz', @bot).msg("[#{message.user.first_name} #{message.user.last_name}] #{message.text}") }
            end
        end
    end
    

  end
end