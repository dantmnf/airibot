# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'open3'

class EvalRb
  include Cinch::Plugin

  match /(?:eval|ruby|rb) (.+)/
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    # TODO: use Docker API
    sin, sout, serr, thr = Open3.popen3("docker run -i --rm archmin-ruby220:fixed3 setuidgid 12450:12450 env -i LANG=zh_CN.UTF-8 timeout -t 2 /usr/bin/ruby --disable=gems -E UTF-8:UTF-8 /evalrb/escaper.rb")
    pid = thr[:pid]
    sin.puts query
    sin.close
    error = ''
    result = sout.read
    sout.close
    error = serr.read
    serr.close
    exit_status = thr.value
    if exit_status == 0 or exit_status == 124
      result = (result.strip.empty?) ? error : result
    else
      result = error
    end
    result = result[0..1024].each_line.take(5).join
    if exit_status == 124
      result << 'error: killed by watchdog'
    end
    m.reply result
  end
end
