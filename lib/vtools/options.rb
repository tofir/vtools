# -*- encoding: binary -*-

module VTools

  # Takes care about passed via ARGV options
  class Options
    class << self
      # parse config data
      def parse! args
        # slice options afer "--" sign if given
        # catch help & version calls
        case
        when(args.include? '--')
          argv = args[ ( args.index('--') + 1)..-1]
        when(args.include? '-h')
          argv = ['-h']
        when(args.include? '-v')
          argv = ['-v']
        else
          return
        end

        # parse passed options
        OptionParser.new do |opts|

          dot = ' ' * 4
          opts.banner = "Usage: vtools <command> <daemon options> -- <options>\n" +
            "\n" +
            "Commands:\n" +
            "#{dot}start         start an instance of the application\n" +
            "#{dot}stop          stop all instances of the application\n" +
            "#{dot}restart       stop all instances and restart them afterwards\n" +
            "#{dot}reload        send a SIGHUP to all instances of the application\n" +
            "#{dot}run           start the application and stay on top\n" +
            "#{dot}zap           set the application to a stopped state\n" +
            "#{dot}status        show status (PID) of application instances\n" +
            "\n" +
            "Daemon options:\n" +

            "#{dot}-t, --ontop                      Stay on top (does not daemonize)\n" +
            "#{dot}-f, --force                      Force operation\n" +
            "#{dot}-n, --no_wait                    Do not wait for processes to stop"

          opts.separator ""
          opts.separator "Options:"

          # add config file
          opts.on("-c", "--config-file FILE", "Use configuration file") do |f|
            CONFIG[:config_file] = f
          end

          # add log file
          opts.on("-l", "--log-file [FILE]", "Log process into file (default STDOUT)") do |l|
            CONFIG[:logging]  = true
            CONFIG[:log_file] = "#{CONFIG[:PWD]}/#{l}" if l
          end

          # include path
          opts.on("-I", "--include PATH",
                  "specify $LOAD_PATH (may be used more than once)") do |path|
            $LOAD_PATH.unshift(*path.split(/:/))
          end

          # connect additional library
          opts.on("-r", "--require LIBRARY",
                  "require the library, before daemon starts") do |library|
            CONFIG[:library] << library
          end

          opts.separator ""

          # VTools version
          opts.on_tail("-v", "--version", "Show current version") do |operator|
            puts VERSION.join(',')
            exit
          end

          # options help
          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end

          # do parse!
          begin
            if argv.empty?
              argv = ["-h"]
              STDERR.puts "ERROR: No command given\n\n"
            end

            opts.parse!(argv)
            Hook.exec :config_parsed # callback
          rescue OptionParser::ParseError => e
            STDERR.puts "ERROR: #{e.message}\n\n", opts
            exit(-1)
          end
        end # OptionParser.new
      end # parse!
    end # class <<
  end # Options
end # VTools