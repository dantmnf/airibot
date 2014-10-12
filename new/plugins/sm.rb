# encoding: UTF-8
require 'cinch'
require 'cgi'
require 'open-uri'
require 'json'
require 'net/http'
class SM
  include Cinch::Plugin

  match /sm (.+)/
  
  def get_sm_message(query)
    response = open('http://xiaofengrobot.sinaapp.com/web.php?callback=jQuery191041205509454157474_1376842442554&para=%s&_=1376842442555' % query).read
    text = JSON.parse('[' + response[5..-2] + ']').first
    text.gsub! /<br ?(\/)? ?>/, ' '
    return text
  end
  
  
  def execute(m, query)
    m.reply(get_sm_message(query), true)
  end
end