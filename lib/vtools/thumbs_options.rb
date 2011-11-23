# -*- encoding: binary -*-

module VTools

  # options for the thumbnailer
  class ThumbsOptions < Hash
    include SharedMethods

    def initialize options = {}

      @ignore = [:thumb_count, :thumb_start_point, :quality, :width, :time, :postfix]
      # default values
      merge!(
        :thumb_count        => 0,
        :thumb_start_point  => 0,
      )

      parse! options
    end

    # redefine native method
    # for more readable options
    def []= index, value
      case
      when [:quality, :q].include?(index)
        former = {:q => value, :quality => value}
      when [:width, :s].include?(index)
        former = {:s => value, :width => value}
      when [:time, :t].include?(index)
        former = {:t => value, :time => value}
      else
        return super
      end
      merge! former
      value
    end

    def to_s
      params = collect do |key, value|
        "-#{key} #{value}" unless @ignore.include?(key)
      end.compact

      params.join " "
    end
    
    # options parser
    def parse! options

      case
      # predefined
      when options.is_a?(String) && CONFIG[:thumb_set].include?(options.to_sym)
        # get config data
        s, q, count, start_point = CONFIG[:thumb_set][options.to_sym]
        options = {:thumb_count => count, :thumb_start_point => start_point, :s => s, :q => q}

      # niether string nor hash..
      when !options.is_a?(Hash)
        raise ConfigError, "Options should be a Hash or String (predefined set)"
      # convert keys to symbols
      else
        options = keys_to_sym options
        # check inline predefined
        parse! options.delete(:set) if options.has_key? :set
      end

      perform options
      merge! options
    end

    private
    # revalidate special options
    def perform hash
      { :quality => :q, :width => :s, :time => :t }.each do |name, orig|
        hash[orig] = hash[name] if hash.include?(name)
      end
    end
  end # ThumbsOptions
end # VTools
