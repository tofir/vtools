# -*- encoding: binary -*-

module VTools

  # job instance
  class Job
    attr_reader   :video, :id

    def initialize config
      @id = self.object_id.to_i
      @config = validate config
      @video  = Video.new @config.file
    end

    # execute job
    def execute
      # start hook
      Hook.exec :job_started, @video, @config.action

      result = @video.get_info # we always get info

      case @config.action
      when /^convert$/i
        result = @video.convert @config.setup # will return video
      when /^thumbs$/i
        result = @video.create_thumbs @config.setup # will return thumbs array
      end

      # final hook
      Hook.exec :job_finished, result, @video, @config.action
      result
    end

    # parse video options
    def validate options
      unless options.action =~ /^convert|thumbs|info$/ && options.file && !options.file.empty?
        raise ConfigError, "Invalid action (config: #{options.marshal_dump})"
      else
        return options if options.action =~ /^info$/
        # empty set error
        raise ConfigError, "Configuration is empty" if !options.setup || options.setup.empty?
      end
      options
    end
  end # Job
end # VTools
