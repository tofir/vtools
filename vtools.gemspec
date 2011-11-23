# -*- encoding: binary -*-

$LOAD_PATH.unshift 'lib'
require "vtools/version"

Gem::Specification.new do |s|

  s.name                    = "vtools"
  s.summary                 = "Daemon tools to operate the video (get info, encode & generate thumbnails)."
  s.description             = File.read(File.join(File.dirname(__FILE__), 'README.md'))

  s.extensions              = 'extconf.rb'
  s.requirements            = ['ffmpeg v >= 1.8', 'ffmpegthumbnailer v >= 2', 'gem Daemons v >= 1.1.4']

  s.files                   = Dir['**/**']
  s.test_files              = Dir["spec/*_spec.rb"]
  s.executables             = ["vtools"]

  s.version                 = VTools::VERSION.join('.')
  s.author                  = "tofir"
  s.email                   = "v.tofir@gmail.com"
  s.homepage                = "http://tofir.comuv.com"
  s.platform                = Gem::Platform::RUBY
  s.required_ruby_version   = ">=1.9"
  
  s.add_dependency              'daemons', '>= 1.1.4'
  s.add_dependency              'json'
  s.add_development_dependency  'rspec'
end
