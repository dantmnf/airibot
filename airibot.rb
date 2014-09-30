#!/usr/bin/env ruby
#encoding: utf-8

require 'base64'
require 'fiber'
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
      @callback_hash = {}
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
      setup_internal_callbacks
      
      @gfw = Airi::GFW.new
      pass Airi::Config::PASS
      # SASL
      if Airi::Config::SASL
        Fiber.new do
          f = Fiber.current
          send_line 'CAP REQ :sasl'

          cb = add_command_callback 'CAP' do |client, msg|
            if msg[2][1] == 'ACK'
              remove_command_callback cb
              f.resume msg
            end
          end

          msg = Fiber.yield

          unless msg[2][2].split(' ').include?('sasl')
            STDERR.puts 'server does not support SASL.'
            next
          end

          send_line 'AUTHENTICATE PLAIN'

          cb = add_command_callback 'AUTHENTICATE' do |client, msg|
            remove_command_callback cb
            f.resume msg
          end
          msg = Fiber.yield

          if msg[2][0] == '+'
            sasl_data = Base64.encode64("#{Airi::Config::NICK}\0#{Airi::Config::SASL_USERNAME}\0#{Airi::Config::SASL_PASSWORD}").strip
            send_line "AUTHENTICATE #{sasl_data}"
            send_line 'CAP END'
          else
            STDERR.puts 'server does not support SASL.'
            next
          end

          cb = add_command_callback '903' do |client, msg|
            f.resume
          end
          Fiber.yield
          irc_init2
        end.resume


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

    def add_command_callback(msg, &cb)
      if msg.is_a? Array
        msg.each {|item| add_command_callback(msg, &cb) }
      elsif msg.is_a? String
        msg = msg.upcase
        if @callback_hash[msg].nil?
          @callback_hash[msg] = [cb]
        else
          @callback_hash[msg].push cb
        end
      end
      return cb
    end

    def remove_command_callback(cb)
      @callback_hash.each do |msg, arr|
        arr.delete cb
      end
    end

    def setup_internal_callbacks
      add_command_callback 'PRIVMSG' do |client, msg|
        parse_msg msg[0], msg[2].first, msg[2][1]
      end

      add_command_callback 'PING' do |client, msg|
        pong msg[2].first
      end
    end

    def parse_line(line)

      begin
        msg = IRCParser.parse_raw line+"\r\n"

        callbacks = @callback_hash.fetch(msg[1], [])
        callbacks.each {|cb| cb.call(self, msg) }

      rescue
        STDERR.print("An error occurred while parsing #{line}\n")
        STDERR.print("#$!\n at #{$@.join "\n"}\n")
      end

    end

    def parse_msg(msg_from, msg_to, msg_content)
      # msg_from: :Nickname!username@hostname
      callermatch_info = /^(.*)!(.*)@(.*)$/.match msg_from
      caller = CallerInfo.new(callermatch_info[1], callermatch_info[2], callermatch_info[3])
      if msg_match_result = /^([Aa]iri[,: ]|~)(.*)$/.match(msg_content)
        return if caller.nick == nick
        if @gfw.log(self, msg_to, caller.nick, caller.user)
          parse_cmd(msg_to, caller, msg_match_result[2].strip)
        end
      elsif msg_content.upcase == "\1VERSION\1"
        message caller.nick, "\1VERSION Airi bot by dantmnf\1"
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

  $keyboard_queue = EM::Queue.new
  EM.connect(Airi::Config::SERVER, Airi::Config::PORT, Airi::IRCClient, $keyboard_queue)
  EM.open_keyboard(KeyboardHandler, $keyboard_queue)
}
