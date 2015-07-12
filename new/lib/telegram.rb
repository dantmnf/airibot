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
      p "Cinch::TelegramSync initialized with token #{token}"
    end
    def start
      @me = @tgbot.get_me
      @tgbot.get_updates(fail_sliently: true) do |message|
        p message
        p ::TGSYNC_GROUPS.rassoc message.chat.id
        if ::TGSYNC_GROUPS.value? message.chat.id
          Target.new(::TGSYNC_GROUPS.rassoc(message.chat.id)[0], @ircbot).msg(format_message(message))
        end
      end
    rescue
      puts $!.to_s
      puts $!.backtrace
      retry
    end
    def format_message(message)
      return if message.text.to_s.empty?
      if message.reply_to_message
        if message.reply_to_message.from.id == @me.id
          orig_text = message.reply_to_message.text
          case orig_text
          when /\A\u2b50/
            reply_to = orig_text.split(' ', 3)[2]
          when /\A\[(\S+)\] /
            reply_to = $1
          end
        else
          reply_to = name_from_user message.reply_to_message.user
        end
        text = "#{reply_to}: " + message.text
      else
        text = message.text
      end
      prefix =  message.user.last_name.nil? ? "[#{message.user.first_name}]" : "[#{message.user.first_name} #{message.user.last_name}]"
      text.each_line.map {|line| "#{prefix} #{line}" unless line.strip.empty? }.join('')
    end

    def name_from_user(user)
      user.last_name.nil? ? user.first_name : "#{user.first_name} #{user.last_name}"
    end
  end
end
