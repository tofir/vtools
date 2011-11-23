# -*- encoding: binary -*-

require 'rake/gempackagetask'

$LOAD_PATH.unshift 'lib'
require "vtools/version"

spec = Gem::Specification.new do |s|
  s.name                    = "vtools"
  s.summary                 = "Daemon tools to operate the video (get info, encode & generate thumbnails)."
  s.description             = File.read(File.join(File.dirname(__FILE__), 'README.md'))
  s.extensions              = 'extconf.rb'
  s.version                 = VTools::VERSION.join('.')
  s.requirements            = ['ffmpeg v >= 1.8', 'ffmpegthumbnailer v >= 2', 'gem Daemons v >= 1.1.4']
  s.author                  = "tofir"
  s.email                   = "v.tofir@gmail.com"
  s.homepage                = "http://tofir.comuv.com"
  s.platform                = Gem::Platform::RUBY
  s.required_ruby_version   = ">=1.9"
  s.files                   = Dir['**/**']
  s.executables             = ["vtools"]
  s.test_files              = Dir["spec/*_spec.rb"]

  s.add_dependency              'daemons', '>= 1.1.4'
  s.add_dependency              'json'
  s.add_development_dependency  'rspec'
end

Rake::GemPackageTask.new(spec).define