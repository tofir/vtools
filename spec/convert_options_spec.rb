require "spec_helper"
require "convert_options"

describe VTools::ConvertOptions do

  # hooks
  before :all do
    @options_base = VTools::ConvertOptions.new({})
  end

  before :each do
    @options = @options_base.dup
  end

  # specs
  context "#[]=" do

    it "places width & height" do
      # place initial value
      @options.merge!({:s => "720x360"})

      # set new values
      @options[:width] = 1024
      @options[:height] = 768

      @options[:width].should == 1024
      @options[:height].should == 768
      @options[:s].should be nil
      @options[:resolution].should be nil
    end

    it "places s" do
      @options[:s]                  = "720x360"

      @options[:s].should           == "720x360"
      @options[:resolution].should  == "720x360"
      @options[:width].should       be 720
      @options[:height].should      be 360
    end

    it "places resolution" do
      # place initial value
      @options.merge!({:s => "720x360"})

      # set new values
      @options[:resolution] = "1024x768"

      @options[:s].should == "1024x768"
      @options[:resolution].should == "1024x768"
    end

    it "places duration" do
      # forward
      @options[:t] = 25
      @options[:t].should == 25
      @options[:duration].should == 25

      # reverse
      @options[:duration] = 45
      @options[:t].should == 45
      @options[:duration].should == 45
    end

    it "places other" do
      @options[:a] = 123
      @options[:a].should == 123
    end
  end


  context "#to_s" do

    # skps ignored values
    it "reates valid string representation" do

      # still empty
      @options.to_s.should == ""

      # skips disallowed keywords
      @options.merge!({
        :width              => 1024,
        :height             => 768,
        :resolution         => "600x400",
        :extension          => '.flv',
        :preserve_aspect    => false,
        :duration           => 123,
        :postfix            => "video",
        :s                  => "640x480",
      })
      @options.to_s.should == "-s 640x480"

      # validate with aspect
      @options[:aspect] = 1.2
      @options.to_s.should == "-s 640x480 -aspect 1.2"
    end
  end

  context "#perform" do

    it "receives recalculate" do
      @options.should_receive(:recalculate).once.and_return{ |str| str.split("x").map(&:to_i) }

      values = {
        :duration => 123,
        :resolution => "600x360",
        :preserve_aspect => true,
      }

      @options.method(:perform).call values

      values.delete(:preserve_aspect)
      @options.method(:perform).call values
    end

    it "converts data valid" do
      @options.should_not_receive(:recalculate)

      values = {
        :duration => 123,
        :resolution => "640x480",
        :width => 600,
        :height => 400,
        :aspect => 1.3,
      }

      # major priority
      @options.method(:perform).call values
      values[:t].should == 123
      values[:s].should == "640x480"

      # middle priority
      values.delete(:resolution)
      @options.method(:perform).call values
      values[:s].should == "600x400"

      # minor priority
      values[:s] = "1024x768"
      values.delete(:preserve_aspect)
      values.delete(:width)
      values.delete(:height)
      @options.method(:perform).call values
      values[:s].should == "1024x768"
    end

    it "deletes invalid dimmensions definition" do
      @options.should_not_receive(:recalculate)

      values = { :width => 600 }
      @options[:s] = "600x400"
      @options.method(:perform).call values
      values[:s].should be nil

      values = { :height => 600 }
      @options[:s] = "600x400"
      @options.method(:perform).call values
      values[:s].should be nil
    end
  end  

  context "#parse!" do

    # set predefined data
    VTools::CONFIG[:video_set][:x264_180p] = [
      'libx264', 'libfaac', '240x180', '96k', '64k',
      22050, 2, 'mp4', '_180', 'normal'
    ]

    let :conf_hash do
      { :s => "240x180", :vcodec => "libx264", :acodec => "libfaac",
        :vb => "96k", :ab => "64k", :ar => 22050, :ac => 2,
        :extension => "mp4", :postfix => "_180", :vpre => "normal" }
    end

    def make_stubs
      @options.stub(:keys_to_sym).and_return{ |hsh| hsh }
      @options.stub(:perform).and_return{ |hsh| hsh }
    end

    it "parses custom hash" do
      make_stubs

      @options.method(:parse!).call({:s => "640x480"}).should == {:s => "640x480"}
      @options.delete(:s)
      @options.method(:parse!).call({:width => 640, :height => 480}).should == {:width => 640, :height => 480}
    end

    it "parses predefined set" do
      make_stubs

      @options.method(:parse!).call("x264_180p").should include conf_hash
    end

    it "parses complex set" do
      make_stubs

      complex = conf_hash.dup
      complex[:s] = "1024x768"

      @options.method(:parse!).call({:set => "x264_180p", :s => "1024x768"}).should include complex
    end

    it "raises error" do
      make_stubs

      expect {@options.method(:parse!).call(123) }.to raise_error VTools::ConfigError
      expect {@options.method(:parse!).call("nonexistent") }.to raise_error VTools::ConfigError
    end
  end  

  context "#recalculate" do

    it "no rescale" do
      @options[:aspect] = nil
      width, height = @options.method(:recalculate).call "1024x768"
      width.should == 1024
      height.should == 768
    end

    it "rescale by aspect > 1 (wide video)" do
      @options[:aspect] = 6.to_f / 5.to_f # original video aspect is 6:5
      { # set max expected video dimm => rescale
        "1024x768" => [922, 768], # we create 4:3
        "1024x576" => [692, 576], # we create 16:9
      }.each do |accept, result|
        width, height = @options.method(:recalculate).call accept
        width.should == result[0]
        height.should == result[1]
      end

      @options[:aspect] = 17.to_f / 8.to_f # original video aspect is 17:8
      { # set max expected video dimm => rescale_result
        "1024x768"  => [1024, 482], # we create 4:3
        "600x436"   => [600, 282], # we create 11:8
      }.each do |accept, result|
        width, height = @options.method(:recalculate).call accept
        width.should == result[0]
        height.should == result[1]
      end
    end

    it "rescale by aspect < 1 (tall video)" do
      @options[:aspect] = 5.to_f / 6.to_f # original video aspect is 5:6
      { # set max expected video dimm => rescale
        "1024x768" => [640, 768], # we create 4:3
        "1024x576" => [480, 576], # we create 16:9
      }.each do |accept, result|
        width, height = @options.method(:recalculate).call accept
        width.should == result[0]
        height.should == result[1]
      end

      @options[:aspect] = 8.to_f / 17.to_f # original video aspect is 8:17
      { # set max expected video dimm => rescale_result
        "1024x768"  => [362, 768], # we create 4:3
        "600x436"   => [206, 436], # we create 11:8
      }.each do |accept, result|
        width, height = @options.method(:recalculate).call accept
        width.should == result[0]
        height.should == result[1]
      end
    end

    it "rescale by aspect = 1 (square video)" do
      @options[:aspect] = 1.to_f / 1.to_f # original video aspect is 1:1
      { # set max expected video dimm => rescale
        "1024x768" => [768, 768], # we create 4:3
        "1024x576" => [576, 576], # we create 16:9
      }.each do |accept, result|
        width, height = @options.method(:recalculate).call accept
        width.should == result[0]
        height.should == result[1]
      end
    end
  end  

  context "#initialize" do
    it "valid calls methods" do
      config = { :width => 1024, :height => 768 }

      VTools::ConvertOptions.any_instance.should_receive(:parse!).with(config)
      options = VTools::ConvertOptions.new config
    end
  end
end
