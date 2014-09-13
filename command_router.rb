 module Airi
  class CommandRouter

    def initialize(client)
      @client = client
      @command_hash = {}
      @command_not_found = proc {}
      register_command_not_found do |cmdline, call_from, caller|
        STDERR.print "Airi::CommandParser: command not found: #{cmdline.strip.split(' ').first}"
      end
    end

    def register(command, &block)
      raise unless block_given?
      if command.is_a? Array
        command.each {|name| register(name, &block) }
      end
      @command_hash[command] = block
    end

    def register_command_not_found(&block)
      @command_not_found = block
    end

    def route(cmdline, call_from, caller)
      STDERR.puts("route(#{cmdline.inspect}, #{call_from.inspect}, #{caller.inspect})")
      cmdline.lstrip!
      command = cmdline.split(' ', 2).first
      parser = @command_hash.fetch(command, @command_not_found)
      parser.call(@client, cmdline, call_from, caller)
    end

    def cmds
      @command_hash.keys
    end
  end
end
      