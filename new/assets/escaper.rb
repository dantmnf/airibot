#!/usr/bin/env ruby
#encoding: utf-8

MEMLIMIT = 96*1024*1024
Process.setrlimit(:RSS, MEMLIMIT, MEMLIMIT) #64M <Linux 2.4.30
Process.setrlimit(:AS, MEMLIMIT, MEMLIMIT)
#Process.setrlimit(:MEMLOCK, MEMLIMIT, MEMLIMIT)
Process.setrlimit(:NPROC, 1, 1)
Process.setrlimit(:CPU, 2, 2)
Process.setrlimit(:RTTIME, 200000, 200000)
if Process.euid == 0
  Process.uid = 'nobody'
end

[:fork,:exec,:load,:require,:require_relative,:spawn,:syscall,:system,:`,:sleep,:open].each {|symb| Kernel.send(:remove_method, symb)}
[:Process,:Thread,:File,:FileTest].each {|symb| Object.send(:remove_const, symb)}
class <<IO
  undef popen
end
#FIXME: other dangerous methods
begin
  result = eval(STDIN.read, nil, 'IRC Message', 1)
rescue Exception
  STDERR.puts("error: " << $!.message)
  exit 1
end

STDERR.puts ' => ' << result.inspect
