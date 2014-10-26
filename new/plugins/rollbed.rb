# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'sqlite3'
class Rollbed
  begin
    dbfile = "/home/dant/airibot/rollbed.db"
    db_exists = FileTest.exist? dbfile
    @@db = SQLite3::Database.new dbfile
    unless db_exists
      @@db.execute <<-'HERESQL'
        CREATE TABLE `ROLLBED` (
        `NICK`      TEXT,
        `COUNT`     INTEGER,
        `LONGEST`   REAL,
        `SHORTEST`  REAL
        );
        INSERT INTO ROLLBED (NICK, COUNT, LONGEST, SHORTEST) VALUES ('Airi', 1, -1, 11);
      HERESQL
    end
  end
  
  include Cinch::Plugin
  
  match /rollbed(?: (.*))?/
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    query = '' if query.nil?
    argv = query.split ' '
    p argv
    if argv[0] == 'stat'
      if argv[1] == '.global'
        # query global record
        global_countmax, global_countmax_name = @@db.execute("SELECT COUNT,NICK FROM ROLLBED ORDER BY COUNT DESC LIMIT 1;")[0]
        global_longest, global_longest_name = @@db.execute("SELECT LONGEST,NICK FROM ROLLBED ORDER BY LONGEST DESC LIMIT 1;")[0]
        global_shortest, global_shortest_name = @@db.execute("SELECT SHORTEST,NICK FROM ROLLBED ORDER BY SHORTEST ASC LIMIT 1;")[0]
        
        m.reply "全局饥渴记录：#{global_countmax_name} 滚床单 #{global_countmax} 次。", true
        m.reply "全局秒【哔】记录：#{global_shortest_name}  #{global_shortest} 秒。", true
        m.reply "全局持久记录：#{global_longest_name}  #{global_longest} 秒。", true
        
      elsif !argv[1].nil?
        # query one's record
        nick = argv[1]
        begin
          count = @@db.execute("SELECT COUNT FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
          longest = @@db.execute("SELECT LONGEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
          shortest = @@db.execute("SELECT SHORTEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
          
          m.reply "#{nick} 共滚床单 #{count} 次。", true
          m.reply "秒【哔】记录： #{shortest} 秒。", true
          m.reply "持久记录：#{longest} 秒。", true
        rescue
          m.reply "这个基佬还没有滚过床单", true
        end
        
      else
        # query my record
        nick = m.user.nick
        begin
          count = @@db.execute("SELECT COUNT FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
          longest = @@db.execute("SELECT LONGEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
          shortest = @@db.execute("SELECT SHORTEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
          m.reply "共滚床单 #{count} 次。", true
          m.reply "秒【哔】记录： #{shortest} 秒。", true
          m.reply "持久记录：#{longest} 秒。", true
        rescue
          m.reply "你个基佬还没有滚过床单", true
        end 
      end
      
      
      
    else
      # rolling in the deep~~~
      rollbed_time = (rand() * 10).round(2)
      #EM.defer do
      count, longest, shortest = @@db.execute("SELECT COUNT,LONGEST,SHORTEST FROM ROLLBED WHERE NICK == '#{m.user.nick}' LIMIT 1;").flatten
      
      global_longest = @@db.execute("SELECT LONGEST FROM ROLLBED ORDER BY LONGEST DESC LIMIT 1;")[0][0]
      global_shortest = @@db.execute("SELECT LONGEST FROM ROLLBED ORDER BY SHORTEST ASC LIMIT 1;")[0][0]
      
      p global_longest, global_shortest
      
      if count.nil?
        @@db.execute("INSERT INTO ROLLBED (NICK) VALUES ('#{m.user.nick}');")
        count = 0
        longest = -1
        shortest = 11
      end
      count += 1
      if rollbed_time > longest
        longest = rollbed_time
        msg = '创造了自己的持久记录。'
        if rollbed_time > global_longest
          msg = '创造了全局持久记录。'
        end
      end
      if rollbed_time < shortest
        shortest = rollbed_time
        msg = '创造了自己的秒【哔】记录。'
        if rollbed_time < global_shortest
          msg = '创造了自己的秒【哔】记录。'
        end
      else
        msg = '建议向游泳教练请教【哔——】的方法。'
      end
      p count, longest, shortest
      @@db.execute("UPDATE ROLLBED SET COUNT = #{count.to_s}, LONGEST = #{longest.to_s}, SHORTEST = #{shortest.to_s} WHERE NICK == '#{m.user.nick}';")
      sleep(rollbed_time)
      m.reply "你坚持了 #{rollbed_time.to_s} 秒，#{msg}", true
    end
  end
end

