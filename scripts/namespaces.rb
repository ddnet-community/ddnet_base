#!/usr/bin/env ruby

class Namespacer
  def initialize(filepath)
    @filepath = filepath
    @lines = []

    @stats = {
      # line number of last include at the start of the file
      # we insert after that line so the default of -1
      # would insert at line 0
      last_include: -1,

      # line number of the include guard closing
      last_endif: 0,
    }
  end

  # patch the source file in place
  def patch
    return if @filepath.end_with? 'detect.h'
    return if @filepath.end_with? 'confusables_data.h'

    parse
    File.open(@filepath, "w+") do |f|
      @lines.each do |line|
        f.puts(line)
      end
    end
  end

  private

  def parse
    File.readlines(@filepath).each_with_index do |line, num|
      track_line(line, num)
    end

    (1..100).each do |i|
      post_include = @lines[@stats[:last_include]+i]
      break if post_include.nil?
      break if post_include[0] != '#'

      puts "shifting last include because it is followed by another post processor instruction"
      @stats[:last_include] += 1
    end

    insert_after_line(@stats[:last_include], open_namespace_str)

    close_ns_at = 'eof'
    if @filepath.end_with? '.h'
      close_ns_at = 'before_endif'
    end
    if @filepath.end_with? 'hash_openssl.cpp'
      close_ns_at = 'before_endif'
    end
    if @filepath.end_with? 'confusables.h'
      close_ns_at = 'eof'
    end

    case close_ns_at
    when 'before_endif'
      insert_before_line(@stats[:last_endif], close_namespace_str)
    when 'eof'
      insert_before_line(@lines.count, close_namespace_str)
    else
      raise 'invalid close'
    end

    puts "stats: #{@stats}"
  end

  def insert_before_line(line_num, line_str)
    insert_at_line(line_num, line_str)
  end

  def insert_after_line(line_num, line_str)
    insert_at_line(line_num + 1, line_str)
  end

  def shift_stats(inserted_line_num, shift_amount)
    # make sure that stats do not get out of sync
    # when patching
    @stats.each do |key, val|
      if val > inserted_line_num
        puts "shifting stats[#{key}] because a line was inserted above"
        @stats[key] = val + shift_amount
      end
    end
  end

  def insert_at_line(line_num, line_str)
    shift_stats(line_num, 1)
    @lines.insert(line_num, line_str)
  end

  def open_namespace_str
    "namespace ddnet_base {\n"
  end

  def close_namespace_str
    "} // end namespace\n"
  end

  def track_line(line, source_num)
    # when tracking stats do not use source_num
    # it gets out of sync on the first patch
    # use @lines.count instead

    if line.match? /^\s*#include/
        if line.match? /^\s*#include <semaphore.h>/
          @lines << close_namespace_str
          @lines << line
          @lines << open_namespace_str
          return
        else
          if @filepath.end_with? 'confusables.cpp'
            if source_num > 20
              @lines << line
              return
            end
          end
          if source_num > 40
            puts "WARNING: high include found please double check."
            puts "         #{@filepath}:#{source_num}"
            puts "         #{line}"
          end
          @stats[:last_include] = @lines.count
        end
    elsif line.match? /^\s*#endif/
      @stats[:last_endif] = @lines.count
    end

    @lines << line
  end
end

source_files = Dir['src/**/*.cpp'] + Dir['src/**/*.h']
source_files.each do |source_file|
  namespacer = Namespacer.new(source_file)
  namespacer.patch
end
