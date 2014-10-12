# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'readline'

module Cinch
  class Console
    include Cinch::Helpers
    
    def initialize(bot)
      @bot = bot
      @detaching = false
      @prefix = ''
    end
    
    def get_prompt
      "[console] #{@prefix == '' ? '<server>' : @prefix} "
    end
    
    def attach
      until @detaching
        buf = Readline.readline(get_prompt, true).to_s
        next if buf.strip == ''
        if buf[0] == '/'
          @bot.synchronize(:console) { parse_command buf[1..-1] }
        else
          @bot.synchronize(:console) { parse_message buf }
        end
      end
    end
    
    def parse_command(line)
      cmd, arg = line.split(' ', 2)
      arg = arg.to_s
      case cmd.upcase
      when 'PREFIX'
        @prefix = arg
      when 'MSG'
        return if arg == ''
        target, content = arg.split(' ', 2)
        Target.new(target, @bot).msg(content)
      when 'NOTICE'
        return if arg == ''
        target, content = arg.split(' ', 2)
        Target.new(target, @bot).notice(content)
      when 'JOIN'
        return if arg == ''
        @bot.join arg
      when 'PART'
        return if arg == ''
        @bot.part arg
      when 'ME'
        return if arg == ''
        if check_prefix?
          content = arg
          Target.new(@prefix, @bot).action(content)
        else
          info 'You should set a prefix before using /me'
        end
      when 'EVAL'
        begin
          eval arg
        rescue
          
        end
      end
    end
    
    def parse_message(msg)
      if check_prefix?
        Target.new(@prefix, @bot).msg(msg)
      else
        @bot.irc.send(msg)
      end
    end
    
    def check_prefix?
      @prefix != ''
    end
    
  end
end