#!/usr/bin/env ruby
# Fixes order of files downloaded from papaya "GitHub...dd-MMM-yyyy.....pdf"
# by prepending "yyyy-mm-dd-" to them"
require 'date'

dry_run = ARGV.delete("--dry-run")
path = ARGV.shift

abort "Please specify a path (e.g.: #{$0} .)\nAdd --dry-run to see what would be renamed." unless path && ARGV.empty?

BAD_FILE = /\AGit.*(?<!\d)(\d?\d-[a-zA-Z][a-zA-Z][a-zA-Z]-20\d\d).*\.pdf\z/
Dir.foreach(path).grep(BAD_FILE) do |filename|
  prefix = Date.parse(filename.match(BAD_FILE).captures.first).strftime("%Y-%m-%d")
  old_name = File.join(path, filename)
  new_name = File.join(path, "#{prefix}-#{filename}")
  puts "#{dry_run ? "Would rename" : "Renaming"} #{old_name} to #{new_name}"
  File.rename(old_name, new_name) unless dry_run
end

