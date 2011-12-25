# -*- encoding: binary -*-

module VTools
  # shared methods
  module SharedMethods
    # both static & instance bindings
    module Common

      @@logger = nil

      # custom logger
      def logger= logger
        @@logger = logger
      end

      # logger mechanics
      def log level, message = ""

        if CONFIG[:logging]
          unless @@logger
            output = CONFIG[:log_file] || STDOUT
            logger = Logger.new(output, 1000, 1024000)
            logger.level = Logger::INFO
            @@logger = logger
          end

          @@logger.send(level, message) if @@logger
        end
      end

      # converts json to the ruby object
      # returns nil on invalid JSON
      def json_to_obj json_str
        hash_to_obj(parse_json(json_str))
      end

      # convert hash into object
      def hash_to_obj hash
        OpenStruct.new(hash) rescue raise ConfigError, "Can't convert setup to object"
      end

      # parse json string into hash
      def parse_json str
        JSON.parse str rescue raise ConfigError, "Invalid JSON"
      end

      # set symbols in place of string keys
      def keys_to_sym hash
        return hash unless hash.is_a? Hash
        hash.inject({}){ |opts,(k,v)| opts[k.to_sym] = v; opts }
      end

      # config accessor
      def config data
        CONFIG[data]
      end

      # calls TCP/IP applications
      def network_call url
        require "socket"

        url =~ %r#^([a-z]+://)?(?:www.)?([^/:]+)(:[\d]+)?(.*)$#
        protocol, host, port, route =
          ($1 || '')[0...-3], $2, ($3 || ":80")[1..-1].to_i, "/#{$4.to_s.gsub(/^\//, '')}"

        begin
          sock = TCPSocket.open(host, port)
          sock.print "GET #{route} HTTP/1.0\r\n\r\n"
          response = sock.read.split("\r\n\r\n", 2).reverse[0]
          sock.close
        rescue => e
          log :error, e
        end

        response
      end

      # function to create correct subdirectories to the file
      def generate_path file_name, scope = "video"
        generator = CONFIG[:"#{scope}_path_generator"]
        begin
          generator = instance_exec(file_name, &generator).to_s if generator.is_a? Proc
        rescue => e
          generator = nil
          raise ConfigError, "Path generator error: (#{e})"
        end

        storage = CONFIG[:"#{scope}_storage"].to_s
        storage += "/" unless storage.empty?
        storage += generator || ""

        path = (!storage || storage.empty? ? CONFIG[:PWD] : storage).to_s.strip.gsub(%r#/+#, '/').gsub(%r#/$#, '')

        # generate path
        begin
          FileUtils.mkdir_p path, :mode => 0755
        rescue => e
          raise FileError, "Path generator error: #{e}"
        end unless File.exists?(path)
        path
      end

      # path generator setter
      def path_generator scope = nil, &block
        if scope
          scope = "thumb" unless scope == "video"
          CONFIG[:"#{scope}_path_generator"] = block
        else
          CONFIG[:thumb_path_generator] = CONFIG[:video_path_generator] = block
        end if block_given?
      end

      # encoding fixer for iso-8859-1
      def fix_encoding(output)
        output[/test/] # Running a regexp on the string throws error if it's not UTF-8
      rescue ArgumentError
        output.force_encoding("ISO-8859-1")
      end
    end # Common

    # class bindings
    module Static
      include Common
      # load external libs
      def load_libs
        CONFIG[:library].each do |lib|
          begin
            require lib
          rescue LoadError => e
            print "Library file could not be found (#{lib})\n"
          rescue SyntaxError => e
            print "Library may contain non ascii characters (#{lib}).\n\n" +
              "Try to set file encoding to 'binary'.\n\n"
          end
        end
      end
    end # Static

    # instance bindings
    module Instance
      include Common
    end # Instance

    # extend it
    def self.included (klass) klass.extend Static end
    include Instance
  end # SharedMethods
end # VTools
