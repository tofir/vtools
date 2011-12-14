require "spec_helper"
require "errors"

#ConfigError
#FileError
#FormatError
#ProcessError

describe VTools do

  # specs
  context "#VToolsError" do

    it "valid exception tree" do
      expect { raise VTools::Error }.to raise_error Exception
    end
  end

  # specs
  context "#ConfigError" do

    it "valid exception tree" do
      expect { raise VTools::ConfigError }.to raise_error VTools::Error
    end
  end

  context "#FileError" do

    it "valid exception tree" do
      expect { raise VTools::FileError }.to raise_error VTools::Error
    end
  end

  context "#FormatError" do

    it "valid exception tree" do
      expect { raise VTools::FormatError }.to raise_error VTools::Error
    end
  end

  context "#ProcessError" do

    it "valid exception tree" do
      expect { raise VTools::ProcessError }.to raise_error VTools::Error
    end
  end
end
