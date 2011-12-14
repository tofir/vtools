# -*- encoding: binary -*-

module VTools

  # options for the video converter
  class ConvertOptions < Hash
    include SharedMethods

    def initialize options = {}, additional = {}
      @ignore = [:width, :height, :resolution, :extension, :preserve_aspect, :duration, :postfix]
      merge! additional
      parse! options
    end

    # set value method
    # backward compatibility for width height & resolution
    def []= (key, value)
      ignore = @ignore[0..2] << :s

      case
      # width & height
      when ignore.first(2).include?(key)
        ignore.last(2).each { |index| delete(index) }
        data = { key => value }
      # resolution
      when ignore.last(2).include?(key)
        ignore.each { |index| delete(index) }
        width, height = value.split("x")
        data = { :width => width.to_i, :height => height.to_i, :resolution => value, :s => value}
      # duration
      when [:duration, :t].include?(key)
        data = { :duration => value, :t => value }
      else
        return super
      end

      merge! data
      return value
    end

    def to_s

      params = collect do |key, value|
        "-#{key} #{value}" unless @ignore.include?(key)
      end.compact

      # put the preset parameters last
      params  = params.reject { |p| p =~ /[avfs]pre/ } + params.select { |p| p =~ /[avfs]pre/ }

      params.join " "
    end

    private
    # string parser for the options
    def parse! options

      case
      # try to convert string into valid ffmpeg values
      when options.is_a?(String) && CONFIG[:video_set].include?(options.to_sym)
        # get config data
        vcodec, acodec, s, vb, ab, ar, ac,
        extension, postfix, vpre = CONFIG[:video_set][options.to_sym]

        # set storage
        options = {
          :vcodec             => vcodec,
          :acodec             => acodec,
          :s                  => s,
          :vb                 => vb,
          :ab                 => ab,
          :ar                 => ar,
          :ac                 => ac,
          :postfix            => postfix,
          :extension          => extension,
          :preserve_aspect    => true,
        }
        options[:vpre] = vpre if vpre

      when !options.is_a?(Hash)
        raise ConfigError, "Options should be a Hash or String (predefined set)"
      else
        options = keys_to_sym options
        # check inline predefined
        parse! options.delete(:set) if options.has_key? :set
      end

      perform options
      merge! options
    end

    # correct width x height | resolution | s values
    def perform hash

      # fix duration
      hash[:t] = hash[:duration] if hash[:duration]

      dimmensions = hash[:resolution] ||
        ("#{hash[:width].to_i}x#{hash[:height].to_i}" if hash[:width] && hash[:height]) ||
        hash[:s]

      if dimmensions
        # recreate dimmensions dimmensions
        if hash[:preserve_aspect]
          width, height = recalculate dimmensions
          dimmensions = "#{width.to_i}x#{height.to_i}"
        end

        hash[:s] = dimmensions
      else
        hash.delete(:s)
      end
    end

    # keep resolution
    def recalculate dimm
      width, height = dimm.split("x").map(&:to_f)

      return [width, height].map(&:to_i) unless self[:aspect]

      # width main:
      if self[:aspect] > 1
        # heigh = -1
        resize = (width / self[:aspect]).round
        resize += 1 if resize.odd? # needed if new_height ended up with no decimals in the first place

        if height < resize
          width = (height * self[:aspect]).round
          width += 1 if width.odd?
        else
          height = resize
        end

      # height main:
      elsif self[:aspect] < 1
        # width = -1
        resize = (height * self[:aspect]).round
        resize += 1 if resize.odd?

        if width < resize
          height = (width / self[:aspect]).round
          height += 1 if height.odd?
        else
          width = resize
        end

      # square:
      else
        width = height
      end

      [width, height].map(&:to_i)
    end

  end # ConverterOptions
end # VTools
