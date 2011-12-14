# -*- encoding: binary -*-

# VTools exceptions
module VTools

  # basic error
  class Error < Exception
  end

  # confuguration error
  class ConfigError < Error
  end

  # specified file does not exist
  class FileError < Error
  end

  # invalid video format
  class FormatError < Error
  end

  # invalid video format
  class ProcessError < Error
  end
end # VTools
