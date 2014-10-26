require 'bundler/setup'
require 'cinch'

class AntiFlood
  LOG_SIZE = 8
  ANTIFLOOD_BURST_DURATION = 30
  BAN_TIME = 60
  def initialize
    @data = {}
    @banlist = {}
  end

  def log(msg)
    target = msg.target.name
    nick = 'nick=' + msg.user.nick
    user = 'user=' + msg.user.user
    @data[target] = {} if @data[target].nil?
    @data[target][nick] = [] if @data[target][nick].nil?
    @data[target][user] = [] if @data[target][user].nil?

    @data[target][user].push Time.now
    @data[target][nick].push Time.now

    @data[target][nick].shift while @data[target][nick].length > LOG_SIZE
    @data[target][user].shift while @data[target][user].length > LOG_SIZE
  end

  def flooding?(msg)
    return false if banned? msg
    target = msg.target.name
    nick = 'nick=' + msg.user.nick
    user = 'user=' + msg.user.user
    
    nicklog = @data[target][nick]
    userlog = @data[target][user]

    result = false
    result = ((nicklog.length >= LOG_SIZE) && (nicklog.last - nicklog.first < ANTIFLOOD_BURST_DURATION))
    result ||= ((userlog.length >= LOG_SIZE) && (userlog.last - userlog.first < ANTIFLOOD_BURST_DURATION))

    return result
  end

  def ban(msg, prompt=true)
    target = msg.target.name
    nick = 'nick=' + msg.user.nick
    user = 'user=' + msg.user.user
    
    @banlist[target] = {} if @banlist[target].nil?
    @banlist[target][nick] = Time.now + BAN_TIME
    @banlist[target][user] = Time.now + BAN_TIME

    msg.reply('Pia!<(=ｏ ‵-′)ノ☆' + msg.user.nick) if prompt
    
  end

  def banned?(msg)
    target = msg.target.name
    nick = 'nick=' + msg.user.nick
    user = 'user=' + msg.user.user
    
    result = (@banlist[target][nick].is_a?(Time) && @banlist[target][nick] > Time.now)
    result ||= (@banlist[target][user].is_a?(Time) && @banlist[target][user] > Time.now)
    
    return result
  rescue
    false
  end
  
  def log_check_and_ban(msg, prompt=true)
    return false if banned? msg
    log msg
    checkresult = flooding? msg
    ban(msg, prompt) if checkresult == true
    return !checkresult
  end
end



