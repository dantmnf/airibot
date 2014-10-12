# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'open3'

class EvalRb
  include Cinch::Plugin

  match /(?:eval|ruby|rb) (.+)/
  
  def execute(m, query)
    sin, sout, serr, thr = Open3.popen3("ruby #{File.dirname(__FILE__)}/../assets/escaper.rb")
    pid = thr[:pid]
    sin.puts query
    sin.close
    error = ''
    t = Timer(5) do
      debug 'timer fire'

      Process.kill(9, pid)
      debug 'killed'
      error = 'error: killed by watchdog'
      m.reply error, true
      t.stop
    end
    result = sout.read
    sout.close
    error = serr.read
    serr.close
    exit_status = thr.value
    t.stop
    if exit_status == 0
      result = (result.strip.empty?) ? error : result
      result.gsub! /(\r|\n)/, ' '
    else
      result = error
    end
    m.reply result, true
  end
end