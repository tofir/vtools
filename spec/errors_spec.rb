require "spec_helper"
require "errors"

#ConfigError
#FileError
#FormatError
#ProcessError

describe VTools do

  # specs
  context "#ConfigError" do

    it "valid exception tree" do
      expect { raise VTools::ConfigError }.to raise_error ArgumentError
    end
  end

  context "#FileError" do

    it "valid exception tree" do
      expect { raise VTools::FileError }.to raise_error Errno::ENOENT
    end
  end

  context "#FormatError" do

    it "valid exception tree" do
      expect { raise VTools::FormatError }.to raise_error IOError
    end
  end

  context "#ProcessError" do

    it "valid exception tree" do
      expect { raise VTools::ProcessError }.to raise_error IOError
    end
  end
end
