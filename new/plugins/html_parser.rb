# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'optparse'
require 'shellwords'
require 'stringio'
require 'curb'
require 'nokogiri'
require 'sanitize'

class HTMLParserPlugin
  include Cinch::Plugin

  match /ht(?-: (.+))?/
  
  def execute(m, query)
    return unless $antiflood.log_check_and_ban m
    stdout = StringIO.new
    parse(('ht ' + query.to_s).shellsplit, stdout)
    m.reply stdout.string, true
  end

  def parse(argv, stdout)
    options = {}
    OptionParser.new do |opts|
      opts.banner = 'HTML/XML parser based on nokogiri. Usage: ht [args] <URL> <selector>'
      opts.on('-c', '--css', 'use CSS selector (default)') {|c|options[:css]=c}
      opts.on('-x', '--xpath', 'use XPath selector') {|x|options[:xpath]=x}
      opts.on('-r', '--raw', "don't parse, selector is ignored") {|r|options[:raw]=r}
      opts.on('-o', '--outer', "don't strip tags") {|o|options[:outer]=o}
      opts.on('-a', '--user-agent UASTR', 'use custom User-Agent header (Firefox by default)') {|u|options[:ua]=u}
      opts.on_tail('-h','--help') { stdout << opts.to_s ; return }
    end.parse!(argv)
    unless argv.length.between?(2,3)
      stdout << 'Pia!'
      return
    end
    argv.shift
    url, selector = argv
    content = Curl::Easy.perform(url) do |curl|
      curl.headers['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0'
      curl.headers['User-Agent'] = options[:ua] if options[:ua]
    end.body_str
    document = Nokogiri.parse content
    case
    when options[:xpath]
      ele = document.at(selector)
    when options[:raw]
      selector = '0-320' unless selector
      l, r = selector.split('-', 2).map(&:to_i)
      if r < l or r-l > 320
        r=l+320
      end
      stdout << content[l..r].each_line.take(5).join
      return
    else
      ele = document.at_css(selector)
    end
    if options[:outer]
      stdout << ele.to_html.each_line.take(5).join
    else
      stdout << Sanitize.fragment(ele.to_html).each_line.take(5).join
    end

  rescue
    p $!
    stdout << '玩坏掉了。'
  end
end
