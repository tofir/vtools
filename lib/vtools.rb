# -*- encoding: binary -*-

module VTools

  # set global $LOAD_PATH
  $: << File.dirname(__FILE__) << Dir.getwd

  Thread.abort_on_exception = true

  require 'optparse'
  require 'json'
  require 'yaml'
  require 'ostruct'
  require 'open3'
  require 'logger'
  require "fileutils"

  require 'vtools/version'
  require 'vtools/errors'
  require 'vtools/shared_methods'
  require 'vtools/config'
  require 'vtools/options'
  require 'vtools/hook'
  require 'vtools/storage'
  require 'vtools/harvester'
  require 'vtools/job'
  require 'vtools/video'
  require 'vtools/converter'
  require 'vtools/thumbnailer'
  require 'vtools/convert_options'
  require 'vtools/thumbs_options'

  include SharedMethods # extend with common methods

  # callbacks after ARGV config has been parsed
  Hook.collection do

    # load external config file & external libs
    set :config_parsed do
      CONFIG.load!
      load_libs
    end

    # set job finished hooks
    set :job_finished do |result, video, action|
      # log job status
      log :info, "Job finished. name: #{video.name},  action : #{action}"
    end

    # set converter error hooks
    set :before_convert do |video, command|
      # log status
      log :info, "Running encoding... (#{video.name}) : #{command}"
    end

    # set converter error hooks
    set :convert_success do |video, output_file|
      # log status
      log :info, "Encoding of #{video.path} to #{output_file} succeeded"
    end

    # set converter error hooks
    set :convert_error do |video, errors, output|
      # log error
      log :error, "Failed encoding... #{video} #{output} #{errors}"
    end

    # set thumbnailer success hooks
    set :thumb_success do |video, thumbs|
      # log status
      log :info, "Thumbnail creation of #{video.path} succeeded"
    end

    # set thumbnailer error hooks
    set :thumb_error do |video, errors|
      # log error
      log :error, "Failed create thumbnail for the video #{video.name} #{errors}"
    end
  end # Hook.collection
end # VTools
