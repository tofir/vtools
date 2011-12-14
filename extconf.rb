# -*- encoding: binary -*-

require 'mkmf'

if find_executable("ffmpeg") || find_executable("ffmpegthumbnailer")
  create_makefile("VTools")
else
  stars = "#{"*" * 10}"
  puts "", stars, "No ffmpeg / ffmpegthumbnailer support available.", stars
end
