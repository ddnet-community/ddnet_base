#!/usr/bin/env ruby

class MacroIfTracker
  attr_reader :stack

  def initialize()
    @stack = []
  end

  def is_ifdef(line)
    return true if line.match? /^\s*#\s*if\s*defined/
    return true if line.match? /^\s*#\s*if\s*!defined/
    return true if line.match? /^\s*#\s*ifdef/
    return true if line.match? /^\s*#\s*ifndef/

    return false
  end

  def is_endif(line)
    return true if line.match? /^\s*#\s*endif/

    return false
  end

  def add_line(line)
    @stack.push(line) if is_ifdef(line)
    @stack.pop if is_endif(line)
  end
end

