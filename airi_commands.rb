module Airi
  module Commands
    module_function
    def setup(router)


%s~
      router.register 'cal' do |client, cmdline, call_from, caller|
        client.message call_from, "#{caller.nick}: #{Time.now.to_s}"
        client.message call_from, "#{caller.nick}: TODO: recent festivals"
      end
~

%s~
      router.register 'sleep' do |client, cmdline, call_from, caller|
        hentai_argv = cmdline.split(' ', 3)
        hentai_argv.shift
        if hentai_argv.length != 0
          sleep_time = hentai_argv.shift.to_f
          wakeup_msg = hentai_argv.join('')
          STDERR.printf('time=%.02f msg=%s', sleep_time, wakeup_msg)
          wakeup_msg = 'waking up' if wakeup_msg.strip == ''
          EM::Timer.new(sleep_time) { client.message call_from, "#{caller.nick}: #{wakeup_msg}" }
        else
          client.message call_from, "#{caller.nick}: usage: sleep <time in second> [wakeup client.message]"
        end
      end
~

      router.register 'rollbed' do |client, cmdline, call_from, caller|

        #FIXME: async db query

        argv = cmdline.split(' ')

        dbfile = "#{File.dirname(__FILE__)}/rollbed.db"
        db_exist = FileTest.exist? dbfile
        db = SQLite3::Database.new dbfile
        unless db_exist
          db.execute %s~
          CREATE TABLE `ROLLBED` (
            `NICK`      TEXT,
            `COUNT`     INTEGER,
            `LONGEST`   REAL,
            `SHORTEST`  REAL
          );
          INSERT INTO ROLLBED (NICK, COUNT, LONGEST, SHORTEST) VALUES ('Airi', 1, -1, 11);
          ~
        end

        # query stat
        if argv[1] == 'stat'
          
          #client.message call_from, "#{caller.nick}: TODO: rollbed stats."


          # query global record
          if argv[2] == '.global'
            global_countmax, global_countmax_name = db.execute("SELECT COUNT,NICK FROM ROLLBED ORDER BY COUNT DESC LIMIT 1;")[0]
            global_longest, global_longest_name = db.execute("SELECT LONGEST,NICK FROM ROLLBED ORDER BY LONGEST DESC LIMIT 1;")[0]
            global_shortest, global_shortest_name = db.execute("SELECT SHORTEST,NICK FROM ROLLBED ORDER BY SHORTEST ASC LIMIT 1;")[0]

            client.message call_from, "#{caller.nick}: 全局饥渴记录：#{global_countmax_name} 滚床单 #{global_countmax} 次。"
            client.message call_from, "#{caller.nick}: 全局秒【哔】记录：#{global_shortest_name}  #{global_shortest} 秒。"
            client.message call_from, "#{caller.nick}: 全局持久记录：#{global_longest_name}  #{global_longest} 秒。"


            # query one's record
          elsif !argv[2].nil?
            nick = argv[2]
            begin
              count = db.execute("SELECT COUNT FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
              longest = db.execute("SELECT LONGEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
              shortest = db.execute("SELECT SHORTEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]

              client.message call_from, "#{caller.nick}: #{nick} 共滚床单 #{count} 次。"
              client.message call_from, "#{caller.nick}: 秒【哔】记录： #{shortest} 秒。"
              client.message call_from, "#{caller.nick}: 持久记录：#{longest} 秒。"
            rescue StandardError
              client.message call_from, "#{caller.nick}: 这个基佬还没有滚过床单"
            end

            # query my record
          else
            nick = caller.nick
            begin
              count = db.execute("SELECT COUNT FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
              longest = db.execute("SELECT LONGEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
              shortest = db.execute("SELECT SHORTEST,NICK FROM ROLLBED WHERE NICK == '#{nick}' LIMIT 1;")[0][0]
              client.message call_from, "#{caller.nick}: 共滚床单 #{count} 次。"
              client.message call_from, "#{caller.nick}: 秒【哔】记录： #{shortest} 秒。"
              client.message call_from, "#{caller.nick}: 持久记录：#{longest} 秒。"
            rescue StandardError
              client.message call_from, "#{caller.nick}: 你个基佬还没有滚过床单"
            end


          end


          # rolling in the deep~~~
        else
          rollbed_time = (rand() * 10).round(2)
          #EM.defer do
          count, longest, shortest = db.execute("SELECT COUNT,LONGEST,SHORTEST FROM ROLLBED WHERE NICK == '#{caller.nick}' LIMIT 1;").flatten
          
          global_longest = db.execute("SELECT LONGEST FROM ROLLBED ORDER BY LONGEST DESC LIMIT 1;")[0][0]
          global_shortest = db.execute("SELECT LONGEST FROM ROLLBED ORDER BY SHORTEST ASC LIMIT 1;")[0][0]

          p global_longest, global_shortest

          if count.nil?
            p 'Inserting new record...'
            db.execute("INSERT INTO ROLLBED (NICK) VALUES ('#{caller.nick}');")
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
              msg = '创造了全局秒【哔】记录。'
            end
          else
            msg = '建议向游泳教练请教【哔——】的方法。'
          end
          p count, longest, shortest
          db.execute("UPDATE ROLLBED SET COUNT = #{count.to_s}, LONGEST = #{longest.to_s}, SHORTEST = #{shortest.to_s} WHERE NICK == '#{caller.nick}';")
          EM::Timer.new(rollbed_time) { client.message call_from, "#{caller.nick}: 你坚持了 #{rollbed_time.to_s} 秒，#{msg}" }
          #end

        end
        db.close
      end

      router.register_command_not_found do |client, cmdline, call_from, caller|
        client.message call_from, "\1ACTION #{caller.nick} <-- 警察叔叔，就是这个人！\1"
      end


      router.register 'help' do |client, cmdline, call_from, caller|
        client.message call_from, "#{caller.nick}: commands: <STUB>cal, rollbed [stat [.global | <name>]], (ruby|rb|eval) <script>"
      end

      router.register ['ruby', 'eval', 'rb'] do |client, cmdline, call_from, caller|
        #TODO: a more safe way

        cmdline = cmdline.split(' ', 2).last
        timer = nil
        spawned_pid = EM.system("ruby", "#{File.dirname(__FILE__)}/escaper.rb", cmdline) do |output,status|
          if status.exitstatus == 0
            timer.cancel
            lines = output.split("\n")
            last_return = lines.pop
            msg = lines.join('')[0...140]
            if msg.strip != ''
              client.message call_from, "#{caller.nick}: #{msg}"
            else
              if last_return.strip != ''
                client.message call_from, "#{caller.nick}: #{last_return}"
              else
                client.message call_from, "#{caller.nick}: => no stdout (maybe fatal error)"
              end
            end
          end
          if status.exitstatus == 1
            timer.cancel
            lines = output.split("\n")
            client.message call_from, "#{caller.nick}: #{lines.last[0...140]}"
          end
        end

        timer = EM::Timer.new(5) do
          begin
            Process.kill(9, spawned_pid)
            client.message call_from, "#{caller.nick}: error: killed by watchdog"
          rescue Errno::ESRCH
          end
        end
      end

      router.register 'pia' do |client, cmdline, call_from, caller|
        pialist = cmdline.split(' ')
        pialist.shift
        pialist.each do |name|
          client.message call_from, "Pia!<(=ｏ ‵-′)ノ☆#{name}"
        end
      end

      require_relative 'tagman'
      $tagmanager = Airi::TagManager.new
      $tagmanager.loadtag "#{File.dirname(__FILE__)}/tags.marshal"
      at_exit { $tagmanager.savetag "#{File.dirname(__FILE__)}/tags.marshal" }
      EM::PeriodicTimer.new(300) { $tagmanager.savetag "#{File.dirname(__FILE__)}/tags.marshal" }
      router.register ['sm', 'sm+'] do |client, cmdline, call_from, caller|
        STDERR.puts cmdline
        smlist = cmdline.split(' ', 3)
        cmd = smlist.shift
        if smlist.empty?
          client.message call_from, "#{caller.nick}: usage: sm name [+tag]"
        end
        p smlist
        name = smlist.shift

        if smlist.empty?
          #get tag
          tag, index, total = $tagmanager.gettag name
          case cmd
          when 'sm'
            msg = "#{caller.nick}: #{tag}"
          when 'sm+'
            msg = "#{caller.nick}: (#{index}/#{total}) #{tag}"
          end
          client.message call_from, msg
        else
          tag = smlist.last[1..-1]
          if $tagmanager.addtag(name, tag) == true
            client.message call_from, "#{caller.nick}: tag added"
          else
            client.message call_from, "#{caller.nick}: tag exists"
          end
        end
      end

    end
  end
end
