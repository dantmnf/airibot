#!/usr/bin/env ruby
#encoding: utf-8

MEMLIMIT = 96*1024*1024
def setrlimit(a,b,c)
  Process.setrlimit a,b,c
rescue
end

setrlimit(:RSS, MEMLIMIT, MEMLIMIT) #64M <Linux 2.4.30
setrlimit(:AS, MEMLIMIT, MEMLIMIT)
setrlimit(:MEMLOCK, MEMLIMIT, MEMLIMIT)
#setrlimit(:CPU, 2, 2)
#setrlimit(:RTTIME, 200000, 200000)
setrlimit(:NOFILE, 4, 4)
undef setrlimit

if Process.euid == 0
  Process.uid = 'nobody'
end

class << IO
  undef popen
  undef read
  undef sysopen
  undef readlines
end
[:fork,:exec,:load,:require,:require_relative,:spawn,:syscall,:system,:'`',:sleep,:open].each {|symb| Kernel.send(:remove_method, symb)}
[:Process,:Thread,:File,:FileTest,:IO,:Dir].each {|symb| Object.send(:remove_const, symb)}
GC.start(full_mark: true, immediate_sweep: true)

#FIXME: other dangerous methods
begin
  STDERR.puts '=> ' + eval(STDIN.read.force_encoding('utf-8').encode('utf-8'), nil, '<IRC Message>', 1).inspect
rescue Exception
  STDERR.puts("error: " + $!.class.name + ': ' + $!.message)
  exit 1
end
