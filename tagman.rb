module Airi

  class TagManager

    def initialize
      @tags = {}
    end

    def addtag(name, tag)
      if @tags[name].nil?
        @tags[name] = []
      end
      unless @tags[name].include? tag
        @tags[name].push tag
        return true
      end
      false
    end

    def gettag(name) #return tag, index, total
      if @tags[name].nil? or @tags[name].empty?
        return 'no tag', 0, 0
      end
      index = rand(@tags[name].length - 1)
      index = 0 if index.is_a? Float
      tag = @tags[name][index]
      return tag, index+1, @tags[name].length
    end

    def loadtag(filename)
      open(filename, 'rb') {|f| @tags = Marshal.load(f) }
    end

    def savetag(filename)
      open(filename, 'wb') {|f| Marshal.dump(@tags, f) }
    end
  end
end