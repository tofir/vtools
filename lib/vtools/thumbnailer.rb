# -*- encoding: binary -*-

module VTools

  # Takes care about generating thumbnails
  # requires ffmpegthumbnailer
  class Thumbnailer
    include SharedMethods

    def initialize video
      @video = video
    end

    # thumbnailer job
    def run

      options = @video.thumbs_options
      errors = []
      thumbs = []
      postfix = options[:postfix]
      @total = options[:thumb_count].to_i

      @output_file = "#{generate_path @video.name, "thumb"}/#{@video.name}_"
      command = "#{CONFIG[:thumb_binary]} -i '#{@video.path}' #{options} "

      # callback
      Handler.exec :before_thumb, @video, options

      # process cicle
      @total.times do |count|

        seconds = (options && options[:t]) || set_point(options || count)

        file = "#{@output_file}#{ postfix || (options && options[:t]) || count }.jpg"
        exec = "#{command} -t #{seconds} -o '#{file}' 2>&1"
        options = nil

        Open3.popen3(exec) do |stdin, stdout, stderr|
          # save thumb if no error
          if (error = VTools.fix_encoding(stdout.readlines).join(" ")).empty?
            thumbs << thumb = {:path => file, :offset => time_offset(seconds)}

            Handler.exec :in_thumb, @video, thumb # callbacks
          else
            errors << "#{error} (#{file})"
          end
        end
      end

      # callbacks
      if errors.empty?
        Handler.exec :thumb_success, @video, thumbs
      else
        errors = " Errors: #{errors.flatten.join(";").gsub(/\n/, ' ')}. "
        Handler.exec :thumb_error, @video, errors
        raise ProcessError, "Thumbnailer error: #{errors}" if thumbs.empty? && @total > 0
      end

      thumbs
    end

    private
    # permits to set checkpoint
    # for the current thumb
    def set_point config

      # start point as config hash given
      checkpoint = if config.is_a? Hash

        case config[:thumb_start_point].to_s
        when /(\d+(\.\d+)?)%$/ # shift in percents
          offset = $1.to_i
        when /(\d+)$/ # shift in seconds
          offset = time_offset $1
        end
      elsif config.is_a? Integer # thumb number
        offset = (config * 100 / @total).to_i
      end

      offset ||= 0
    end

    # calculates time offset string
    # by given seconds length
    def time_offset seconds
      shift = (@video.duration > seconds.to_f ? seconds : @video.duration).to_i
      hours, mins = (shift / 360), (shift / 60)
      sec = shift - (hours * 360 + mins * 60)
      "%02d:%02d:%02d" % [hours, mins, sec]
    end
  end # Thumbnailer
end # VTools
