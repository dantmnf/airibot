# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'curb'
require 'nokogiri'


class WebTitle
  include Cinch::Plugin

  match /([Hh][Tt][Tt][Pp][Ss]?:\/\/[^\s]+)/, use_prefix: false
  match /titlecfg (on|off)/, method: :titlecfg
  @@enabled = false

  def get_url_info(url, redirected = 0)
    if redirected > 10
      "⇪错误：重定向次数过多"
    end
    response = Curl::Easy.new url
    response.timeout = 5
    response.useragent = 'Mozilla/5.0 (X11; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0'
    response.headers = {'Range' => '0-16384'}
    response.http_get
    case response.response_code
    when 301, 302
      return get_url_info(response.redirect_url, redirected + 1)
    when 200, 206

      if response.content_type.include? 'html'
        nkgr = Nokogiri.parse response.body
        title = begin
          nkgr.title.nil? ? '<no title>' : nkgr.title
        rescue
          '<no title>'
        end
        title.gsub! /(\r|\n)/, ''
        msg = "⇪标题：#{title}"
        msg << " (重定向到 #{url} )" if redirected != 0
      else
        msg = "⇪MIME: #{response.content_type}"
        mr = nil
        response.head.each_line do |line|
          if r = /^Content-Length: ([0-9]+)$/.match(line.strip)
            mr = r
            break
          end
        end

        if mr
          msg << " 长度：#{mr[1]}"
        end
        msg << " (重定向到 #{url} )" if redirected != 0
      end
    else
      #error
      msg = "⇪错误：#{response.status}"
    end
    return msg
  rescue Curl::Err::TimeoutError
    "⇪错误：超时"
#  rescue
    "⇪错误：" << $!.message
  end

  def execute(m, query)
    return unless @@enabled
    return unless $antiflood.log_check_and_ban m
    url = query
    s = get_url_info(url)
    m.reply(s) unless s.strip.empty?
  end

  def titlecfg(m, query)
    @@enabled = (query == 'on')
    m.reply('WebTitle is %s.' % Format(:bold, (@@enabled ? 'enabled' : 'disabled')), true)
  end
end
