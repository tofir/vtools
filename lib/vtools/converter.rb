# -*- encoding: binary -*-

module VTools

  # Video converter itself
  class Converter
    include SharedMethods

    # constructor
    def initialize video
      @video = video
    end


    # ffmpeg converter cicle
    #
    # ffmpeg <  0.8: frame=  413 fps= 48 q=31.0 size=    2139kB time=16.52 bitrate=1060.6kbits/s
    # ffmpeg >= 0.8: frame= 485 fps= 46 q=31.0 size=   45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def run

      @options = @video.convert_options
      @output_file = "#{generate_path @video.name}/#{@video.name}#{@options[:postfix]}.#{@options[:extension]}"

      command = "#{CONFIG[:ffmpeg_binary]} -y -i '#{@video.path}' #{@options} '#{@output_file}'"
      output = ""
      convert_error = true

      # before convert callbacks
      Handler.exec :before_convert, @video, command

      # process video
      Open3.popen3(command) do |stdin, stdout, stderr|
        stderr.each "r" do |line|
          VTools.fix_encoding line
          output << line

          # we know, that all is not so bad, if "time=" at least once met
          if line.include? "time="

            convert_error = false # that is why, we say "generally it's OK"

            if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
              time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
            elsif line =~ /time=(\d+.\d+)/ # ffmpeg 0.7 and below style
              time = $1.to_f
            else # in case of unexpected output
              time = 0.0
            end
            progress = time / @video.duration

            # callbacks
            Handler.exec :in_convert, @video, progress
          end
        end
      end

      raise ProcessError, output.split("\n").last if convert_error # exit on error

      # callbacks
      unless error = encoding_invalid?
        Handler.exec :convert_success, @video, @output_file
      else
        Handler.exec :convert_error, @video, error, output
        raise ProcessError, error # raise exception in error
      end

      encoded
    end

    # define if encoded succeed
    def encoding_invalid?
      unless File.exists?(@output_file)
        return "No output file created"
      end

      unless encoded.valid?
        return "Encoded file is invalid"
      end

      if CONFIG[:validate_duration]
        # reavalidate duration
        precision = @options[:duration] ? 1.5 : 1.1
        desired_duration = @options[:duration] && @options[:duration] < @video.duration ? @options[:duration] : @video.duration

        if (encoded.duration >= (desired_duration * precision) or encoded.duration <= (desired_duration / precision))
          return "Encoded file duration is invalid (original/specified: #{desired_duration}sec, got: #{encoded.duration}sec)"
        end
      end

      false
    end

    # encoded media
    def encoded
      @encoded ||= Video.new(@output_file).get_info
    end
  end # Converter
end # VTools
