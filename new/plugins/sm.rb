# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'cgi'
require 'open-uri'
require 'json'
require 'net/http'
class SM
  include Cinch::Plugin

  match /sm (.+)/
  
  def get_sm_message(query)
    response = open('http://xiaofengrobot.sinaapp.com/web.php?callback=jQuery191041205509454157474_1376842442554&para=%s&_=1376842442555' % CGI::escape(query)).read
    text = JSON.parse('[' + response[5..-2] + ']').first
    text.gsub! /<br ?(\/)? ?>/, ' '
    text.gsub! /\r/, ''
    text.gsub! /\n/, ''
    return text
  end
  
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    m.reply(get_sm_message(query), true)
  end

  match /LQYMGT([1-7])$/i, method: :lqymgt
  def lqymgt(m, n)
    n.to_i.times do
      return unless $antiflood.log_check_and_ban m
      m.reply(get_sm_message('LQYMGT'), true)
    end
  end
end
