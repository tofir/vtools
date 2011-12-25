# -*- encoding: binary -*-

$LOAD_PATH.unshift "lib"
require "vtools/version"

Gem::Specification.new do |s|

  s.name                    = "vtools"
  s.summary                 = "Daemon tools to operate the video (get info, encode & generate thumbnails)."
  s.description             = "FFMPEG & FFMPEGTHUMBNAILER based video processor. Permits to generate thumbs and encode/edit video. Can be started as daemon."

  s.requirements            = ["ffmpeg v >= 0.5", "ffmpegthumbnailer v >= 2", "gem Daemons v >= 1.1.4"]

  s.files                   = Dir["**/**"]
  s.test_files              = Dir["spec/*_spec.rb"]
  s.executables             = ["vtools"]
  s.extensions              = ["extconf.rb"]

  s.version                 = VTools::VERSION.join(".")
  s.author                  = "tofir"
  s.email                   = "v.tofir@gmail.com"
  s.homepage                = "https://github.com/tofir/vtools"
  s.platform                = Gem::Platform::RUBY
  s.required_ruby_version   = ">=1.9"

  s.add_dependency              "daemons", ">= 1.1.4"
  s.add_dependency              "json"
  s.add_development_dependency  "rspec"
end
