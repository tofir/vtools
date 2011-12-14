# -*- encoding: binary -*-

module VTools

  # Takes care about jobs
  class Harvester
    include SharedMethods
    @jobs           = {}
    @run_jobs       = 0

    # get job info
    class << self

      # collector
      def daemonize!

        Storage.connect # connect jobs pool
        loop do

          with_error_handle do # catch job exceptions
            config = json_to_obj Storage.recv
            add_job config
          end if CONFIG[:max_jobs] > @run_jobs

          sleep CONFIG[:harvester_timer]
        end
      end

      # set new job
      def add_job config

        job = Job.new config

        @jobs[job.id] = job
        @run_jobs += 1

        # execute job
        Thread.new(job, config) do
          # catch job exceptions here
          with_error_handle do # catch job exceptions
            Storage.send({ :data => job.execute, :action => config.action })
          end
          finish job # in any case close job instance
        end
      end

      private
      # job terminator
      def finish job
        job = job.id if job.is_a? Job
        return unless @jobs.has_key? job
        @run_jobs -= 1
        @jobs.delete job
      end

      # error hook
      def with_error_handle &block
        # catch job exceptions here
        begin
          yield if block_given?
        # configuration, create video after convert, valid video file & process
        rescue ConfigError, FileError, FormatError, ProcessError => e
          log :error, "JOB rejected, #{e}"
        rescue => e # uncknown error
          log :fatal, "#{e}"
          raise e
        end
      end
    end # << class
  end # Harvester
end # VTools
