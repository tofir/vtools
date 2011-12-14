require "spec_helper"
require "options"

describe VTools::Options do

  # hooks
  before :all do

  end

  # around to test inside the methods

  before do

  end

  after do

  end

  after :all do

  end

  # specs
  context "#parse!" do

    it "creates valid options" do
      opts =    ["server_commnad", "-option_one", "--", "-app_option", "-app_option_two",]
      opts_v =  opts.dup << "-v"
      opts_h =  opts_v.dup << "-h"

      @test = nil
      OptionParser.stub!(:new).and_return nil

      VTools::Options.stub!(:argv=).and_return do |arr|
        arr.should_not include ["server_commnad", "-option_one", "--"]
        arr.should include ["-app_option", "-app_option_two"]
      end

      VTools::Options.parse! opts

      VTools::Options.stub!(:argv=).and_return { |arr| arr.should == ["-v"] }
      VTools::Options.parse! opts_v

      VTools::Options.stub!(:argv=).and_return { |arr| arr.should == ["-h"] }
      VTools::Options.parse! opts_h
    end

  end

end
