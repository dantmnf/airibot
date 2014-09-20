#!/usr/bin/env ruby
#encoding: utf-8
require 'base64'
require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
require 'em/protocols/saslauth'
require 'irc_parser'
require 'irc_parser/messages'
require 'sqlite3'


require_relative 'lib/commands'
require_relative 'command_router'
require_relative 'airi_commands'
require_relative 'global_flood_wall'

load "#{File.dirname(__FILE__)}/airicfg.rb"

module Airi

  CallerInfo = Struct.new(:nick, :user, :host)

  class IRCClient < EM::Connection
    attr_reader :router

    def send_line(line)
      print "> ", line, "\n"
      send_data(line + "\r\n")
    end

    include EM::Protocols::SASLauthclient
    include EM::Protocols::LineText2
    include IRC::Commands

    attr_reader :queue

    #alias :send_data_airi :send_data
    #def send_data(data)
    #  print "> ", data
    #  send_data_airi(data)
    #end

    def initialize(q)
      @queue = q

      cb = Proc.new do |msg|
        console_command msg
        q.pop &cb
      end

      q.pop &cb
    end

    def console_command(cmd)
      if cmd[0] == '~'
        begin
          eval cmd[1..-1]
        rescue
          p $!
        end
      else
        send_line cmd
      end
    end

    def connection_completed
      if Airi::Config::SSL == true
        start_tls
      else
        irc_init
      end
    end

    def ssl_handshake_completed
      irc_init
    end

    def setup_router
      @router = Airi::CommandRouter.new(self)
      Airi::Commands.setup(@router)
    end

    def irc_init

      setup_router
      @gfw = Airi::GFW.new
      pass Airi::Config::PASS
      # SASL
      if Airi::Config::SASL
        send_line 'CAP REQ :sasl'
      else
        
        irc_init2
      end
      
    end

    def irc_init2
      nick Airi::Config::NICK
      user Airi::Config::USER, 0, Airi::Config::REAL_NAME
      Airi::Config::INITIAL_COMMANDS.each {|cmd| send_line cmd }
      join *Airi::Config::JOIN_CHANNELS
    end

    def receive_line(line)
      print "< ", line, "\n"
      parse_line line
    end

    def parse_line(line)

      begin
        msg = IRCParser.parse_raw line+"\r\n"
        case msg[1]
        when 'PRIVMSG'
          parse_msg msg[0], msg[2].first, msg[2][1]
        when 'PING'
          pong msg[2].first
        when 'CAP'
          if msg[2][2].split(' ').include?('sasl')
            send_line 'AUTHENTICATE PLAIN'
          end
        when 'AUTHENTICATE'
          if msg[2][0] == '+'
            sasl_data = Base64.encode64("#{Airi::Config::NICK}\0#{Airi::Config::SASL_USERNAME}\0#{Airi::Config::SASL_PASSWORD}").strip
            send_line "AUTHENTICATE #{sasl_data}"
            send_line 'CAP END'
          end
        when '903'
          irc_init2
        end
      rescue Exception, StandardError
        STDERR.print("An error occurred while parsing #{line}\n")
        STDERR.print("#$!\n at #{$@.join "\n"}\n")
      rescue
        STDERR.print("An error occurred while parsing #{line}\n")
        STDERR.print("#$!\n at #{$@.join "\n"}\n")
      end

    end

    def parse_msg(msg_from, msg_to, msg_content)
      # msg_from: :Nickname!username@hostname
      hentai_info = /^(.*)!(.*)@(.*)$/.match msg_from
      if msg_match_result = /^([Aa]iri[,: ]|~)(.*)$/.match(msg_content)
        caller = CallerInfo.new(hentai_info[1], hentai_info[2], hentai_info[3])
        return if caller.nick == nick
        if @gfw.log(self, msg_to, caller.nick, caller.user)
          parse_cmd(msg_to, caller, msg_match_result[2].strip)
        end
      end
    end

    def parse_cmd(msg_to, hentai_info, hentai_cmdline)
      @router.route(hentai_cmdline, msg_to, hentai_info)
    end

    def unbind
      EM.stop
    end

    def reload_commands
      load("#{File.dirname(__FILE__)}/airi_commands.rb")
      setup_router
    end

  end
end

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  attr_reader :queue

  def initialize(q)
    @queue = q
  end

  def receive_line(data)
    @queue.push(data)
  end
end

EM.run {

  trap('INT') { EM.stop }
  trap('TERM') { EM.stop }

  q = EM::Queue.new
  #FIXME: SSL connection
  EM.connect(Airi::Config::SERVER, Airi::Config::PORT, Airi::IRCClient, q)
  EM.open_keyboard(KeyboardHandler, q)
}
