module IRC
  # Client commands
  # @see http://tools.ietf.org/html/rfc2812 RFC 2812
  module Commands
    # Set connection password
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.1 3.1.1 Password message
    def pass(password)
      send_line("PASS #{password}")
    end

    # Set/get user nick
    # @return [String] nick if no param
    # @return nil otherwise
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.2 3.1.2 Nick Message
    def nick(nick = nil)
      if nick
        send_line("NICK #{nick}")
      else
        @nick
      end
    end

    # Set username, hostname, and realname
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.3 3.1.3 User Message
    def user(username, mode, realname)
      send_line("USER #{username} #{mode} * :#{realname}")
    end

    # Gain operator privledges
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.4 3.1.4 Oper Message
    def oper(name, password)
      send_line("OPER #{name} #{password}")
    end

    # Set user mode
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.5 3.1.5 Mode Message
    def mode(nickname, setting)
      raise NotImplementedError.new
    end

    # Register a new service
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.6 3.1.6 Service Message
    def service(nickname, reserved, distribution, type)
    end

    # Terminate connection
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.7 3.1.7 Quit
    def quit(message = 'leaving')
      send_line("QUIT :#{message}")
    end

    # Disconnect server links
    # @see http://tools.ietf.org/html/rfc2812#section-3.1.8 3.1.8 Squit
    def squit(server, message = "quiting")
      raise NotImplementedError.new
    end

    # Join a channel
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.1 3.2.1 Join message
    # @example
    #   client.join("#general")
    #   client.join("#general", "fubar")  # join #general with fubar key
    #   client.join(['#general', 'fubar'], "#foo")  # join multiple channels
    def join(*args)
      raise ArgumentError.new("Not enough arguments") unless args.size > 0
      channels, keys = [], []
      args.map!  {|arg| arg.is_a?(Array) ? arg : [arg, '']}
      args.sort! {|a,b| b[1].length <=> a[1].length}  # key channels first
      args.each  {|arg|
        channels << arg[0]
        keys     << arg[1] if arg[1].length > 0
      }
      send_line("JOIN #{channels.join(',')} #{keys.join(',')}".strip)
    end

    # Part all channels
    def part_all
      join('0')
    end

    # Leave a channel
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.2 3.2.2 Part message
    # @example
    #   client.part('#general')
    #   client.part('#general', '#foo')
    #   client.part('#general', 'Bye all!')
    #   client.part('#general', '#foo', 'Bye all!')
    def part(*args)
      raise ArgumentError.new("Not enough arguments") unless args.size > 0
      message = channel?(args.last) ? "Leaving..." : args.pop
      send_line("PART #{args.join(',')} :#{message}")
    end

    # Set channel mode
    # @todo name conflict with user MODE message
    def channel_mode
      raise NotImplementedError.new
    end

    # Set/get topic
    # @param topic [Mixed] String, nil
    #   non-blank string sets the topic
    #   blank string unsets the topic
    #   nil returns the current topic (default)
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.4 3.2.4 Topic message
    def topic(channel, message = nil)
      message = message.nil? ? "" : ":#{message}"
      send_line("TOPIC #{channel} #{message}".strip)
    end

    # List all nicknames visible to user
    # @param args [Multiple] list of channels to list nicks
    #   if last argument is a hash, then :target can request
    #   which server generates response
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.5 3.2.5 Names message
    def names(*args)
      options = args.extract_options!
      send_line("NAMES #{args.join(',')} #{options[:target]}".strip)
    end

    # List channels and topics
    # @param args [Multiple] list of channels
    #   if last argument is a hash, then :target can request
    #   which server generates response
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.6 3.2.6 List message
    def list(*args)
      options = args.extract_options!
      send_line("LIST #{args.join(',')} #{options[:target]}".strip)
    end


    # Invite a user to a channel
    # @param nickname [String] to invite
    # @param channel  [String] to invite to
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.7 3.2.7 Invite message
    def invite(nickname, channel)
      send_line("INVITE #{nickname} #{channel}")
    end

    # Kick a user from a channel
    # @param args [Multiple]
    # @example
    #   client.kick('#general', 'jch')
    #   client.kick('#general', '&bar', 'jch', 'wcc')
    # @see http://tools.ietf.org/html/rfc2812#section-3.2.8 3.2.8 Kick message
    def kick(*args)
      channels = args.select {|arg| channel?(arg)}
      nicks    = args.select {|arg| !channel?(arg)}
      raise ArgumentError.new("Missing channels") if channels.empty?
      send_line("KICK #{channels.join(',')} #{nicks.join(',')}".strip)
    end

    # Send message to user or channel
    # @param target [String] nick or channel name
    # @param message [String]
    # @see http://tools.ietf.org/html/rfc2812#section-3.3.1 3.3.1 Private message
    def privmsg(target, message)
      send_line("PRIVMSG #{target} :#{message}")
    end
    alias_method :message, :privmsg

    # Send message to user or channel
    # @param target [String] nick or channel name
    # @param message [String]
    # @see http://tools.ietf.org/html/rfc2812#section-3.3.2 3.3.2 Notice message
    def notice(target, message)
      send_line("NOTICE #{target} :#{message}")
    end

    # Get message of the day for a server or current server
    # @param target [String] server name or current server if nil
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.1 3.4.1 Motd message
    def motd(target = nil)
      send_line("MOTD #{target}".strip)
    end

    # List users
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.2 3.4.2 Lusers message
    def lusers(mask = nil, target = nil)
      send_line("LUSERS #{mask} #{target}".strip)
    end

    # Get server version
    # @param target [String] server or current server if nil
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.3 3.4.3 Version message
    def version(target = nil)
      send_line("VERSION #{target}".strip)
    end

    # Get stats for a server
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.4 3.4.4 Stats message
    def stats(query = nil, target = nil)
      send_line("STATS #{query} #{target}".strip)
    end

    # List all servernames
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.5 3.4.5 Links message
    def links(remote_server = nil, server_mask = nil)
      send_line("LINKS #{remote_server} #{server_mask}".strip)
    end

    # Get server local time
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.6 3.4.6 Time message
    def time(target = nil)
      send_line("TIME #{target}".strip)
    end

    # Connect to another server
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.7 3.4.7 Connect message
    def server_connect(target, port, remote = nil)
      send_line("CONNECT #{target} #{port} #{remote}".strip)
    end

    # Find the route to a specific server
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.8 3.4.8 Trace message
    def trace(target = nil)
      send_line("TRACE #{target}".strip)
    end

    # Find info about admin of a given server
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.9 3.4.9 Admin message
    def admin(target = nil)
      send_line("ADMIN #{target}".strip)
    end

    # Describe server information
    # @see http://tools.ietf.org/html/rfc2812#section-3.4.10 3.4.10 Info message
    def info(target = nil)
      send_line("INFO #{target}".strip)
    end

    # List services connected to network
    # @see http://tools.ietf.org/html/rfc2812#section-3.5.1 3.5.1 Servlist message
    def servlist(mask = nil, type = nil)
      send_line("SERVLIST #{mask} #{type}".strip)
    end
    alias_method :server_list, :servlist

    # Send a message to a service
    # @see http://tools.ietf.org/html/rfc2812#section-3.5.2 3.5.2 Squery message
    def squery(service, text)
      send_line("SQUERY #{service} :#{text}")
    end

    # Get info about a user
    # @see http://tools.ietf.org/html/rfc2812#section-3.6.1 3.6.1 Who message
    def who(mask, mode = 'o')
      send_line("WHO #{mask} #{mode}")
    end

    # Get user information about a list of users
    # @param args [Multiple]
    #   if last arg is a hash, :target specifies which server to query
    # @see http://tools.ietf.org/html/rfc2812#section-3.6.2 3.6.2 Whois message
    def whois(*args)
      options = args.extract_options!
      target = options[:target] ? "#{options[:target]} " : ''
      send_line("WHOIS #{target}#{args.join(',')}")
    end

    # Get user information that no longer exists (nick changed, etc)
    # @param args [Multiple] list of nicknames
    # @param options [Hash]
    # @option options [Integer] :count number of history entries to list
    # @option options [Integer] :target
    # @example
    #   client.whowas('jch')
    #   client.whowas('jch', 'foo')
    #   client.whowas('jch', 'foo', :count => 5, :target => 'irc.net')
    # @see http://tools.ietf.org/html/rfc2812#section-3.6.3 3.6.3 Whowas message
    def whowas(*args)
      options = args.extract_options!
      send_line("WHOWAS #{args.join(',')} #{options[:count]} #{options[:target]}".strip)
    end

    # Terminate a connection by nickname
    # @see http://tools.ietf.org/html/rfc2812#section-3.7.1 3.7.1 Kill message
    def kill(nickname, comment = "Connection killed")
      send_line("KILL #{nickname} :#{comment}".strip)
    end

    # Test connection is alive
    # @see http://tools.ietf.org/html/rfc2812#section-3.7.2 3.7.2 Ping message
    def ping(server, target = '')
      send_line("PING #{server} #{target}".strip)
    end

    # Respond to a server ping
    # @see http://tools.ietf.org/html/rfc2812#section-3.7.3 3.7.3 Pong message
    def pong(*servers)
      send_line("PONG #{servers.join(' ')}")
    end

    # Server serious or fatal error, or to terminate a connection on quit
    # @see http://tools.ietf.org/html/rfc2812#section-3.7.4 3.7.4 Error message
    def error(message)
      send_line("ERROR :#{message}")
    end

    # Set user as away with optional message
    # @see http://tools.ietf.org/html/rfc2812#section-4.1 4.1 Away
    def away(message = nil)
      send_line("AWAY " + (message ? ":#{message}" : ""))
    end

    # Force user to re-read config
    # @see http://tools.ietf.org/html/rfc2812#section-4.2 4.2 Rehash message
    def rehash
      send_line("REHASH")
    end

    # Shutdown server
    # @see http://tools.ietf.org/html/rfc2812#section-4.3 4.3 Die message
    def die
      send_line("DIE")
    end

    # Restart server
    # @see http://tools.ietf.org/html/rfc2812#section-4.4 4.4 Restart
    def restart
      send_line("RESTART")
    end

    # Ask user to join IRC
    # @see http://tools.ietf.org/html/rfc2812#section-4.5 4.5 Summon
    def summon(user, target = nil, channel = nil)
      send_line("SUMMON #{user} #{target} #{channel}".strip)
    end

    # List logged in users
    # @see http://tools.ietf.org/html/rfc2812#section-4.6 4.6 Users
    def users(target = nil)
      send_line("USERS #{target}".strip)
    end

    # Broadcast to all logged in users
    # @see http://tools.ietf.org/html/rfc2812#section-4.7 4.7 Operwall
    def wallops(message)
      send_line("WALLOPS :#{message}")
    end
    alias_method :broadcast, :wallops

    # Returns information about up to 5 nicknames
    # @see http://tools.ietf.org/html/rfc2812#section-4.9 4.9 Userhost
    def userhost(*nicks)
      raise ArgumentError.new("Wrong number of arguments") unless nicks.size > 0 && nicks.size <= 5
      send_line("USERHOST #{nicks.join(' ')}")
    end

    # Efficient way to check if nicks are currently on
    # @see http://tools.ietf.org/html/rfc2812#section-4.9 4.9 Ison
    def ison(*nicks)
      send_line("ISON #{nicks.join(' ')}")
    end
  end
end
