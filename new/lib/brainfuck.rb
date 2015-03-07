#!/usr/bin/env ruby

class BrainFuck
  UnbalanceedBracketsError = Class.new(RuntimeError)
  def initialize
    @ops = create_ops
    @tape = Array.new(1024,0)
    @tp = 0
    @code = []
    @cp = 0
    @output = ''
  end

  def compile c
    brackets = 0
    c.split("").each do |o|
      case o
      when '['
        brackets += 1
        @code << o
      when ']'
        brackets -= 1
        @code << o
      when @ops.method(:has_key?)
        @code << o
      end
    end
    raise UnbalanceedBracketsError if brackets != 0
    return self
  end

  def run
    while @cp < @code.size
      run_op @code[@cp]
    end
    @cp = 0
    @output
  end

  private

  def run_op op
    @ops[op].call
    @cp += 1
  end

  def get_input
    @tape[@tp] = STDIN.getc
    # getc returns nil on EOF. We want to use 0 instead.
    @tape[@tp] = 0 unless @tape[@tp]
  end

  def create_ops
    { ">" => Proc.new { @tp = (@tp == @tape.size - 1 ? 0 : @tp + 1) },
      "<" => Proc.new { @tp = (@tp == 0 ? @tape.size - 1 : @tp - 1) },
      "+" => Proc.new { @tape[@tp] += 1 },
      "-" => Proc.new { @tape[@tp] -= 1 },
      "." => Proc.new { @output << @tape[@tp].chr if @tape[@tp] },
#      "," => Proc.new { get_input },
      "[" => Proc.new { jump_to_close if @tape[@tp] == 0 },
      "]" => Proc.new { jump_to_open unless @tape[@tp] == 0 }
    }
  end

  def jump_to_close
    level = 1
    while @cp < @code.size
      @cp += 1
      if @code[@cp] == '['
        level += 1
      elsif @code[@cp] == ']'
        level -= 1
      end
      break if level == 0
    end
  end

  def jump_to_open
    level = 1
    while @cp >= 0
      @cp -= 1
      if @code[@cp] == ']'
        level += 1
      elsif @code[@cp] == '['
        level -= 1
      end
      break if level == 0
    end
  end
end

if __FILE__ == $0
  app =  BrainFuck.new
  File.open(ARGV[0], 'r') { |f|
    app.compile(f.read)
  }
  print app.run
end
