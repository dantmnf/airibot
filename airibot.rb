#!/usr/bin/env ruby
#encoding: utf-8
require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
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
      send_data(line + "\r\n")
    end

    include EM::Protocols::LineText2
    include IRC::Commands

    attr_reader :queue

    alias :send_data_airi :send_data
    def send_data(data)
      print "> ", data
      send_data_airi(data)
    end

    def initialize(q)
      @queue = q

      cb = Proc.new do |msg|
        send_line msg
        q.pop &cb
      end

      q.pop &cb
      setup_router
      @gfw = Airi::GFW.new
    end

    def setup_router
      @router = Airi::CommandRouter.new(self)
      Airi::Commands.setup(@router)
    end

    def post_init
      pass Airi::Config::PASS
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
        end
      rescue StandardError, SQLite3::SQLException
        STDERR.print("An error occurred while parsing #{line}\n")
        STDERR.print("#$!\n at #{$@.join "\n"}\n")
      end

    end

    def parse_msg(msg_from, msg_to, msg_content)
      # msg_from: :Nickname!username@hostname
      hentai_info = /^(.*)!(.*)@(.*)$/.match msg_from
      if msg_match_result = /^(ACTION )?[Aa]iri[: ](.*)$/.match(msg_content)
        caller = CallerInfo.new(hentai_info[1], hentai_info[2], hentai_info[3])
        if @gfw.check(caller.nick, caller.user)
          parse_cmd(msg_to, caller, msg_match_result[2].strip)
        else
          if @gfw.last_flag(caller.nick, caller.user)
            message msg_to, "#{caller.nick}: [抗洪防洪，人人有责]"
          end
        end
      end
    end

    def parse_cmd(msg_to, hentai_info, hentai_cmdline)
      @router.route(hentai_cmdline, msg_to, hentai_info)
    end

    def unbind
      EM.stop
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

  EM.connect('chat.freenode.net', 6667, Airi::IRCClient, q)
  EM.open_keyboard(KeyboardHandler, q)
}
