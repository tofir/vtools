require "spec_helper"
require "thumbs_options"

describe VTools::ThumbsOptions do

  # hooks
  before :all do
    @options_base = VTools::ThumbsOptions.new({})
  end

  before :each do
    @options = @options_base.dup
  end

  # specs
  context "#[]=" do

    it "places quality" do
      # place initial value
      @options.merge!({:q => 10})

      # set new values
      @options[:q] = 5
      @options[:q].should == 5
      @options[:quality].should == 5
      # set new values
      @options[:quality] = 7
      @options[:q].should == 7
      @options[:quality].should == 7
    end

    it "places width" do
      # place initial value
      @options.merge!({:width => 256})

      # set new values
      @options[:s] = 128
      @options[:s].should == 128
      @options[:width].should == 128

      @options[:width] = 360
      @options[:s].should == 360
      @options[:width].should == 360
    end

    it "places time" do
      # :time, :t
      # place initial value
      @options.merge!({:t => 150})

      # set new values
      @options[:t] = 45
      @options[:t].should == 45
      @options[:time].should == 45

      @options[:time] = 89
      @options[:t].should == 89
      @options[:time].should == 89
    end

    it "places other" do
      @options[:a] = 123
      @options[:a].should == 123
    end
  end

  context "#to_s" do

    # [:thumb_count, :thumb_start_point, :quality, :width, :time, :postfix]
    # skps ignored values
    it "creates valid string representation" do

      # still empty
      @options.to_s.should == ""

      # skips disallowed keywords
      @options.merge! :thumb_count        => 10,
                      :thumb_start_point  => 25,
                      :quality            => 5,
                      :width              => 600,
                      :time               => 123,
                      :postfix            => "thumb",
                      :s                  => 640

      @options.to_s.should == "-s 640"
    end
  end

  context "#perform" do

    it "converts valid data" do
      values = { :quality => 5, :width => 600, :time => 123 }
      @options.method(:perform).call values
      
      values[:q].should == values[:quality]
      values[:s].should == values[:width]
      values[:t].should == values[:t]
    end
  end

  context "#parse!" do

    # set predefined data
    VTools::CONFIG[:thumb_set][:w600] = [600, 8, 5, 0]

    let :conf_hash do
      { :s => 600, :q => 8, :thumb_count => 5, :thumb_start_point => 0 }
    end

    def make_stubs
      @options.stub(:perform).and_return{ |hsh| hsh }
    end

    it "raises error on invlaid data" do
      expect { @options.method(:parse!).call "123" }.to raise_error VTools::ConfigError
      expect { @options.method(:parse!).call [] }.to raise_error VTools::ConfigError
    end

    it "accepts hash" do
      make_stubs

      @options.method(:parse!).call(:s => 600).should == { :s => 600,
        :thumb_count=>0, :thumb_start_point=>0 }

      @options.delete(:s)
      @options.method(:parse!).call( :width => 600, :thumb_count=>2,
        :thumb_start_point=>3 ).should == { :width => 600, :thumb_count=>2,
        :thumb_start_point=>3 }
    end

    it "accepts string (predefined set)"do
      make_stubs

      @options.method(:parse!).call("w600").should include conf_hash
    end

    it "accepts mixed data" do
      make_stubs
      complex = conf_hash.dup
      complex[:s] = 1024

      @options.method(:parse!).call({:set => "w600", :s => 1024}).should include complex
    end
  end

  context "#initialize" do

    it "valid calls methods" do
      config = { :width => 1024, :t => 7 }

      VTools::ThumbsOptions.any_instance.should_receive(:parse!).with(config)

      options = VTools::ThumbsOptions.new config

      options[:thumb_count].should == 0
      options[:thumb_start_point].should == 0
    end
  end
end
