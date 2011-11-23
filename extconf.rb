# -*- encoding: binary -*-

# validate if ffmpeg & ffmpegthumbnails exists
ffmpeg      = `which ffmpeg`
thumbnailer = `which ffmpegthumbnailer`

puts "\n*---------------> Could not find ffmpeg/ffmpegthumbnailer.. <---------------*\n" if thumbnailer.empty? || ffmpeg.empty?
