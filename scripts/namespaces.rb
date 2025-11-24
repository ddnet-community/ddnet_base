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

      # estimated line number of include guard opening
      include_guard: -1,

      # line number of the include guard closing
      last_endif: -1,
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

  def delete_snippet(filename, lines)
    return unless @filepath.end_with? "/#{filename}"

    match_at = 0

    @lines.each_with_index do |line, i|
      full_match = true
      lines.each_with_index do |snip_line, k|
        if @lines[i+k].chomp != snip_line
          full_match = false
          break
        end
      end
      next unless full_match

      match_at = i
    end

    if match_at == 0
      puts "WARNING: snippet in file #{@filepath} not found!"
      return
    end

    puts "matched snippet at #{match_at}"
    @lines.slice!(match_at, lines.count)
    shift_stats(match_at, lines.count)
  end

  def delete_snippets
    delete_snippet(
      "types.h",
      [
        "template<>",
        "struct std::hash<NETADDR>",
        "{",
        "	size_t operator()(const NETADDR &Addr) const noexcept;",
        "};"
      ])
    delete_snippet(
      "system.cpp",
      [
        "size_t std::hash<NETADDR>::operator()(const NETADDR &Addr) const noexcept",
        "{",
        "	size_t seed = std::hash<unsigned int>{}(Addr.type);",
        "	seed ^= std::hash<std::string_view>{}(std::string_view(reinterpret_cast<const char *>(Addr.ip), sizeof(Addr.ip))) + 0x9e3779b9 + (seed << 6) + (seed >> 2);",
        "	seed ^= std::hash<unsigned short>{}(Addr.port) + 0x9e3779b9 + (seed << 6) + (seed >> 2);",
        "	return seed;",
        "}"
      ])
    delete_snippet(
      "md5.h",
      [
        "#ifdef __cplusplus",
        'extern "C" ',
        "{",
        "#endif",
      ])
    delete_snippet(
      "md5.h",
      [
        "#ifdef __cplusplus",
        '}  /* end extern "C" */',
        "#endif"
      ])
  end

  def parse
    File.readlines(@filepath).each_with_index do |line, num|
      track_line(line, num)
    end

    if @stats[:last_include] != -1
      100.times do
        post_include = @lines[@stats[:last_include]+1]
        p post_include
        break if post_include.nil?
        break if post_include[0] != '#'

        puts "shift last include because its followed by: #{post_include}"
        @stats[:last_include] += 1
      end
    end

    if @stats[:last_include] == -1 && @stats[:include_guard] != -1 && @filepath.end_with?('.h')
      # if the file has no includes
      # we patch after the include guard
      insert_after_line(@stats[:include_guard], open_namespace_str)
    else
      insert_after_line(@stats[:last_include], open_namespace_str)
    end

    close_ns_at = 'eof'
    if @filepath.end_with?('.h') && @stats[:last_endif] != -1
      close_ns_at = 'before_endif'
    end
    if @filepath.end_with? 'hash_openssl.cpp'
      close_ns_at = 'before_endif'
    end
    if @filepath.end_with? 'confusables.h'
      close_ns_at = 'eof'
    end
    if @filepath.end_with? 'crashdump.cpp'
      # we already close twice in the tracker
      close_ns_at = 'never'
    end

    case close_ns_at
    when 'before_endif'
      if @stats[:last_endif] == -1
        raise "In file #{@filepath} tried to insert after last endif but none was found"
      end

      insert_before_line(@stats[:last_endif], close_namespace_str)
    when 'eof'
      insert_before_line(@lines.count, close_namespace_str)
    when 'never'
    else
      raise 'invalid close'
    end

    delete_snippets

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

    prev_line = @lines.last

    if @filepath.end_with?('crashdump.cpp') && source_num > 40
      if line.match? /void crashdump_init/
          @lines << open_namespace_str
      elsif line.match? /#endif/
          @lines << close_namespace_str
      end
    end

    # patch C++ includes
    if @filepath.end_with?('md5.cpp')
      if line == "#include <string.h>\n"
        line = "#include <cstring>\n"
      end
    end

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
    elsif line.match?(/^\s*#\s*define /)
      if prev_line.match?(/#\s*ifndef/) && prev_line.match?(/(BASE_|_INCLUDED)/)
        @stats[:include_guard] = @lines.count
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

# namespacer = Namespacer.new('src/ddnet_base/base/unicode/tolower_data.h')
# namespacer.patch
