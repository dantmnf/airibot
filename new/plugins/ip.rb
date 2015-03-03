# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'cgi'
require 'open-uri'
require 'json'
require 'ipaddr'
require 'socket'
require 'qqwry'
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
      msg = hsh['data'].values_at(*%w(country region city county isp)).reject{|s| s.strip.empty? }.join(' ')
    else
      msg = hsh['data']
    end
    msg
  end
  
  def qqwry(addr)
    return 'not supported' if addr.ipv6?
    db = QQWry::Database.new('qqwry.dat')
    r = db.query addr.to_s
    "#{r.country} #{r.area}"
  end
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    msg = resolve(query.strip).each do |addr|
      m.reply [addr.to_s, ptr(addr), get_ip_info(addr)].join(' '), true
    end
  end

  match /(?-:qqwry|cz) (.+)/, method: :execute_qqwry
  def execute_qqwry(m, query)
    return unless $antiflood.log_check_and_ban m
    msg = resolve(query.strip).each do |addr|
      m.reply [addr.to_s, ptr(addr), qqwry(addr)].join(' '), true
    end
  end
end
