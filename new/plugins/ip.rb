# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'cgi'
require 'open-uri'
require 'json'
require 'ipaddr'
require 'socket'
class IPQuery
  include Cinch::Plugin

  match /ip (.+)/
  
  def resolve(name)
    Socket.gethostbyname(name)[3..-1].map{|n|IPAddr.new_ntoh(n)}
  end

  def ptr(addr)
    Socket.gethostbyaddr(addr.hton).first
  rescue
    ""
  end

  def get_ip_info(addr)
    return 'not supported yet' if addr.ipv6?
    response = open('http://ip.taobao.com/service/getIpInfo.php?ip=' + CGI::escape(addr.to_s)).read
    hsh = JSON response
    p hsh 
    if hsh['code'] == 0
      msg = hsh['data'].values_at(*%w(country area region city county isp)).join(' ')
    else
      msg = hsh['data']
    end
    msg
  end
  
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    msg = resolve(query.strip).map {|addr| [addr.to_s, ptr(addr), get_ip_info(addr)].join(' ') }.join("\n")
    m.reply(msg, true)
  end
end
