module Airi
  class GFW # Global Flood Wall
    def initialize
      @nick_log = {}
      @user_log = {}
      @nick_lastflag = {}
      @user_lastflag = {}
    end

    def check(client, nick, user)
      check_nick(nick) && check_user(user)
    end

    def check_nick(nick)
      result = true
      if @nick_log[nick].nil?
        @nick_log[nick] = [Time.now]
      else
        time2 = Time.now
        @nick_log[nick].push time2
        if @nick_log[nick].length > 4
          time1 = @nick_log[nick].shift
          #p time1,time2
          if time2 - time1 < 10
            result = false
          end
        end
      end
      @nick_lastflag[nick] = result
      return result
    end

    def check_user(user)
      result = true
      if @user_log[user].nil?
        @user_log[user] = [Time.now]
      else
        time2 = Time.now
        @user_log[user].push time2
        if @user_log[user].length > 4
          time1 = @user_log[user].shift
          if time2 - time1 < 10
            result =  false
          end
        end
        @nick_lastflag[user] = result
        return result
      end
    end

    def last_nick_flag(nick)
      @nick_lastflag[nick] ? true : false
    end

    def last_user_flag(user)
      @user_lastflag[user] ? true : false
    end

    def last_flag(nick, user)
      last_user_flag(user) || last_nick_flag(nick)
    end

  end
end
