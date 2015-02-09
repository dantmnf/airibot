# encoding: UTF-8
require 'bundler/setup'
require 'cinch'
require 'v8'
require 'json'

class EvalJS
  include Cinch::Plugin

  match /js (.+)/
  
  def execute(m, query)
    context = V8::Context.new timeout: 500
    result = context.eval query
    result = result.is_a?(V8::Object) ? result.to_s : result.inspect
    m.reply('=> ' + result)
  rescue => e
    m.reply(e.class.name + ': ' + e.message)
  end

end
