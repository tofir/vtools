# -*- encoding: binary -*-

# VTools exceptions
module VTools

  # confuguration error
  class ConfigError < ArgumentError
  end

  # specified file does not exist
  class FileError < Errno::ENOENT
  end

  # invalid video format
  class FormatError < IOError
  end

  # invalid video format
  class ProcessError < IOError
  end
end # VTools
