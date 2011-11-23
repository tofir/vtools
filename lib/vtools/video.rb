# -*- encoding: binary -*-

module VTools

  # Video instance
  class Video 

    attr_reader :path, :name, :duration, :start, :bitrate,
                :video_stream, :video_codec, :video_bitrate, :colorspace, :frame_rate,
                :resolution, :dar, :audio_stream, :audio_codec, :audio_bitrate,
                :audio_sample_rate,
                :convert_options, :thumbs_options

    def to_json(*args)
      ignore = [:@convert_options, :@thumbs_options, :@converter, :@thumbnailer, :@uncertain_duration, :invalid]

      hsh = instance_variables.inject({}) do |data, var|
        data[ var[1..-1] ] = instance_variable_get(var) unless ignore.include? var.to_sym
        data
      end

      hsh["valid"] = !@invalid
      hsh.to_json(*args)
    end

    def initialize path

      @invalid = true
      @uncertain_duration = true
      @convert_options  = {}
      @thumbs_options   = {}
      @path = set_path path

      path =~ /([^\/\\]+?)(\.\w+)?$/
      @name = $1

      raise FileError, "the file '#{@path}' does not exist" unless File.exists?(@path)

      @converter    = Converter.new self
      @thumbnailer  = Thumbnailer.new self
    end

    # generate thumbs
    def create_thumbs setup = {}
      @thumbs_options = ThumbsOptions.new setup.merge({:aspect => calculated_aspect_ratio})
      @thumbnailer.run
    end

    # convert video
    def convert setup = {}
      @convert_options = ConvertOptions.new(setup)
      @converter.run
    end

    # generate video informatioin
    def get_info

      stdin, stdout, stderr = Open3.popen3("#{CONFIG[:ffmpeg_binary]} -i '#{@path}'")
      # Output will land in stderr
      output = stderr.read
      VTools.fix_encoding output

      output[/Duration: (\d{2}):(\d{2}):(\d{2}\.\d{1})/]
      @duration = ($1.to_i*60*60) + ($2.to_i*60) + $3.to_f

      output[/start: (\d*\.\d*)/]
      @start = $1.to_f

      output[/bitrate: (\d*)/]
      @bitrate = $1.to_i || nil

      output[/Video: (.*)/]
      @video_stream = $1

      output[/Audio: (.*)/]
      @audio_stream = $1

      @uncertain_duration = true #output.include?("Estimating duration from bitrate, this may be inaccurate") || @start > 0

      if @video_stream
        @video_codec, @colorspace, resolution, video_bitrate = @video_stream.split(/\s?,\s?/)
        @video_bitrate = video_bitrate =~ %r(\A(\d+) kb/s\Z) ? $1.to_i : nil
        @resolution = resolution.split(" ").first rescue nil # get rid of [PAR 1:1 DAR 16:9]
        @dar = $1 if @video_stream[/DAR (\d+:\d+)/]
      end

      if @audio_stream
        @audio_codec, audio_sample_rate, @audio_channels, unused, audio_bitrate = @audio_stream.split(/\s?,\s?/)
        @audio_bitrate = audio_bitrate =~ %r(\A(\d+) kb/s\Z) ? $1.to_i : nil
        @audio_sample_rate = audio_sample_rate[/\d*/].to_i
      end

      @invalid = false unless @video_stream.to_s.empty?
      @invalid = true if output.include?("is not supported")

      self
    end

    def valid?
      not @invalid
    end

    # validate duration
    def uncertain_duration?
      @uncertain_duration
    end

    def width
      resolution.split("x").first.to_i rescue nil
    end

    def height
      resolution.split("x").last.to_i rescue nil
    end

    # aspect ratio calculator
    def calculated_aspect_ratio
      if dar
        w, h = dar.split(":")
        w.to_f / h.to_f
      else
        aspect = width.to_f / height.to_f
        (aspect.nan? || aspect == 1.0/"x".to_f) ? nil : aspect
      end
    end

    # video file size
    def size
      File.size(@path)
    end

    # valid audio channels index
    def audio_channels
      return nil unless @audio_channels
      return @audio_channels[/\d*/].to_i if @audio_channels["channels"]
      return 1 if @audio_channels["mono"]
      return 2 if @audio_channels["stereo"]
      return 6 if @audio_channels["5.1"]
    end

    def frame_rate
      video_stream[/(\d*\.?\d*)\s?fps/] ? $1.to_f : nil
    end

    private
    # set full path to the file
    def set_path path
      work_dir = CONFIG[:temp_dir].empty? ? CONFIG[:PWD] : CONFIG[:temp_dir]
      path[%r#^(([a-z]:)|/)#i] ? path : "#{work_dir.strip.gsub(%r#/$#, '')}/#{path}"
    end
  end
end
