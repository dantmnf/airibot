# encoding: UTF-8
require 'cinch'
require 'curb'
require 'nokogiri'


class WebTitle
  include Cinch::Plugin

  match URI.regexp, use_prefix: false
  match /titlecfg (on|off)/, method: :titlecfg
  @@enabled = true

  def get_url_info(url, redirected = false)

    response = Curl::Easy.new url
    response.timeout = 5
    response.http_head
    case response.response_code
    when 301, 302
      return get_url_info(response.redirect_url, true)
    when 200

      if response.content_type.include? 'html'
        htmlreq = Curl::Easy.new url
        htmlreq.timeout = 10
        htmlreq.http_get
        nkgr = Nokogiri.parse htmlreq.body
        title = begin
          nkgr.title.nil? ? '<no title>' : nkgr.title
        rescue
          '<no title>'
        end
        msg = "⇪标题：#{title}"
        msg << " (重定向到 #{url} )" if redirected
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
      end

    else
      #error
      msg = "⇪错误：#{response.status}"
    end
    return msg
  rescue Curl::Err::TimeoutError
    "⇪错误：超时"
  rescue
    nil
  end

  def execute(m)
    return unless @@enabled
    url = URI.regexp.match(m.message).to_s
    s = get_url_info(url)
    m.reply(s) unless s.strip.empty?
  end

  def titlecfg(m, query)
    @@enabled = (query == 'on')
    m.reply('WebTitle is %s.' % Format(:bold, (@@enabled ? 'enabled' : 'disabled')), true)
  end
end
