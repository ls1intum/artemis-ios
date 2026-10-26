#!/usr/bin/env ruby

paths = ARGV.flat_map { |pattern| Dir.glob(pattern) }.select { |path| File.file?(path) }.uniq
abort 'error: No build logs found for warning verification.' if paths.empty?

warnings = []
paths.each do |path|
  File.foreach(path).with_index(1) do |line, number|
    text = line.gsub(/\e\[[0-9;]*m/, '')
    warnings << "#{path}:#{number}: #{text.strip}" if text.match?(/(?:^|\s)warning:/i)
  end
end

unless warnings.empty?
  warn warnings.first(30).join("\n")
  abort "error: Build emitted #{warnings.length} warning diagnostics."
end
puts "Verified #{paths.length} build logs: no warning diagnostics."
