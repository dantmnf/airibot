module Airi
  class GFW # Global Flood Wall
    def initialize
      @nick_log = {}
      @user_log = {}
      @nick_blocked = {} # {"nick": Time}
      @user_blocked = {}
    end

    def log(client, channel, nick, user)
      result1 = check_nick(client, channel, nick) 
      result2 = check_user(user)
      result1 && result2
    end

    def check_nick(client, channel, nick)
      now = Time.now
      unblock_time = @nick_blocked[nick]
      if !unblock_time.nil? 
        if unblock_time > now
          return false
        else
          @nick_blocked.delete nick
        end
      end
      result = true
      if @nick_log[nick].nil?
        @nick_log[nick] = [now]
      else
        @nick_log[nick].push now
        if @nick_log[nick].length > 6
          time1 = @nick_log[nick].shift
          #p time1,time2
          if now - time1 < 30
            @nick_blocked[nick] = now + 30
            client.message channel, "#{nick}: (Airi::GFW) 空路由封禁30秒（此消息仅提示一次）"
            result = false
          end
        end
      end
      return result
    end


    def check_user(user)
      now = Time.now
      unblock_time = @user_blocked[user]
      if !unblock_time.nil? 
        if unblock_time > now
          return false
        else
          @user_blocked.delete user
        end
      end
      result = true
      if @user_log[user].nil?
        @user_log[user] = [now]
      else
        @user_log[user].push now
        if @user_log[user].length > 6
          time1 = @user_log[user].shift
          #p time1,time2
          if now - time1 < 30
            @user_blocked[user] = now + 30
            result = false
          end
        end
      end
      return result
    end



  end
end
