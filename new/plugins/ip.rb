# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'cgi'
require 'open-uri'
require 'json'
class IPQuery
  include Cinch::Plugin

  match /ip (.+)/
  
  def get_ip_info(query)
    response = open('http://ip.taobao.com/service/getIpInfo.php?ip=' + CGI::escape(query)).read
    JSON.parse(response).inspect
  end
  
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    m.reply(get_ip_info(query), true)
  end
end
