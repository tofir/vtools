require "spec_helper"
require "video"

describe VTools::Video do

  # hooks
  before do
    VTools::CONFIG[:temp_dir] = ""
    VTools::CONFIG[:PWD] = ""
    VTools::Converter.stub!(:new) { nil }
    VTools::Thumbnailer.stub!(:new) { nil }

    @video = VTools::Video.new __FILE__
  end

  # specs
  context "#to_json" do

    # wtf with this rspec ?!
    it "collects valid json" do

      Open3.stub!(:popen3).and_return [nil, nil, StringIO.new("")]
      @video.get_info

      ignore = [:@convert_options, :@thumbs_options, :@converter, :@thumbnailer, :@uncertain_duration]
      collect = {:path => nil, :name => nil, :duration => nil, :start => nil, :bitrate => nil, :video_stream => nil, :audio_stream => nil}

      @video.instance_variables.inject({}) do |data, var|
        data[ var[1..-1] ] = instance_variable_get(var) unless ignore.include? var.to_sym
        data
      end.should include collect
    end
  end

  context "#create_thumbs" do

    it "executes thumbnailer" do
      thumb = double(nil)
      @video.instance_variable_set(:@thumbnailer, thumb)

      setup = { :thumb => "options" }
      VTools::ThumbsOptions.should_receive(:new).with(setup)
      thumb.should_receive(:run)

      @video.create_thumbs setup
    end
  end

  context "#convert" do

    it "executes converter" do
      convert = double(nil)
      @video.stub(:calculated_aspect_ratio).and_return(1.2)
      @video.instance_variable_set(:@converter, convert)

      setup = { :convert => "options" }
      VTools::ConvertOptions.should_receive(:new).with(setup, {:aspect => 1.2})
      convert.should_receive(:run)

      @video.convert setup
    end
  end

  context "#get_info" do

    let(:path) { "#{File.realpath(File.dirname(__FILE__))}/fixtures/outputs/" }

    def stub_io
      output_stub = StringIO.new(File.read(path))
      Open3.stub!(:popen3).and_return([ nil, nil, output_stub ] )
      @video.get_info
    end

    context "parses data valid" do

      it "iso-8859-1" do
        path << "file_with_iso-8859-1.txt"
        stub_io

        @video.should be_valid

        @video.duration.should == 1482.6
        @video.start.should == 0.0
        @video.bitrate.should == 546

        @video.video_bitrate.should == 480
        @video.colorspace.should == "yuv420p"
        @video.resolution.should == "1000x600"
        @video.frame_rate.should == 25

        @video.audio_sample_rate.should == 44100
        @video.audio_bitrate.should == 64
        @video.audio_channels.should == 1
        @video.audio_codec.should == "aac"
      end

      it "non supported audio" do
        path << "file_with_non_supported_audio.txt"
        stub_io

        @video.should_not be_valid
      end

      it "no audio" do
        path << "file_with_no_audio.txt"
        stub_io

        @video.should be_valid
      end

      it "surround audio" do
        path << "file_with_surround_sound.txt"
        stub_io

        @video.should be_valid
        @video.audio_channels.should == 6
      end

      it "start value" do
        path << "file_with_start_value.txt"
        stub_io

        @video.should be_valid
        @video.start.should == 13.038000
      end
    end
  end

  context "#uncertain_duration?" do

    it "returns uncertain_duration statement" do
      @video.uncertain_duration?.should be

      @video.instance_variable_set(:@uncertain_duration, false)

      @video.uncertain_duration?.should_not be
    end
  end

  context "#width" do

    it "returns valid width" do
      @video.stub(:resolution) { "1024x768" }

      @video.width.should == 1024

      @video.stub(:resolution) { "" }
      @video.width.should == 0

      @video.stub(:resolution) { nil }
      expect { @video.width.should be nil }.to_not raise_error
    end
  end

  context "#height" do

    it "returns valid height" do
      @video.stub(:resolution) { "1024x768" }

      @video.height.should == 768

      @video.stub(:resolution) { "" }
      @video.height.should == 0

      @video.stub(:resolution) { nil }
      expect { @video.height.should be nil }.to_not raise_error
    end
  end

  context "#calculated_aspect_ratio" do

    it "returns dar statement" do
      @video.stub(:dar) { "16:9" }
      @video.calculated_aspect_ratio.should == (16.0/9.0)
    end

    it "returns width / height statement" do
      @video.stub(:width) { 1024 }
      @video.stub(:height) { 768 }

      @video.calculated_aspect_ratio.should == (4.0/3.0)

      @video.stub(:height) { nil }
      @video.stub(:width) { "qwe" }

      @video.calculated_aspect_ratio.should be nil

      @video.stub(:height) { "asd" }

      @video.calculated_aspect_ratio.should be nil
    end
  end

  context "#size" do

    it "responds with size" do
      File.should_receive(:size).with( @video.instance_variable_get(:@path) )
      @video.size
    end
  end

  context "#audio_channels" do

    it "returns valid channels count" do

      @video.audio_channels.should_not be

      @video.instance_variable_set(:@audio_channels, "5.1")
      @video.audio_channels.should == 6

      @video.instance_variable_set(:@audio_channels, "stereo")
      @video.audio_channels.should == 2

      @video.instance_variable_set(:@audio_channels, "mono")
      @video.audio_channels.should == 1

      @video.instance_variable_set(:@audio_channels, "3 channels")
      @video.audio_channels.should == 3
    end
  end

  context "#frame_rate" do

    it "returns valid frame rate" do
      @video.instance_variable_set(:@video_stream, "h264, yuv420p, 720x304, PAR 1:1 DAR 45:19, 23.98 tbr, 25fps, 1k tbn, 47.95 tbc")
      @video.frame_rate.should == 25.0

      @video.instance_variable_set(:@video_stream, "h264, yuv420p, 720x304, PAR 1:1 DAR 45:19, 23.98 tbr, 1k tbn, 47.95 tbc")
      @video.frame_rate.should_not be
    end
  end

  context "#set_path" do

    it "sets valid path" do
      VTools::CONFIG[:temp_dir] = ""
      VTools::CONFIG[:PWD] = "pwd/dir"

      @video.method(:set_path).call("test/path/").should == "pwd/dir/test/path/"

      VTools::CONFIG[:temp_dir] = "temp/dir"
      @video.method(:set_path).call("test/path/").should == "temp/dir/test/path/"

      @video.method(:set_path).call("/test/path/").should == "/test/path/"

      @video.method(:set_path).call("C://test/path/").should == "C://test/path/"
    end
  end

  context "#initialize" do

    it "creates instance valid" do
      VTools::CONFIG[:PWD] = "/root"
      File.stub!(:exists?) { true }
      VTools::Converter.stub!(:new) { nil }
      VTools::Thumbnailer.stub!(:new) { nil }

      video = VTools::Video.new "test/path"

      video.instance_variable_get(:@invalid).should be
      video.instance_variable_get(:@uncertain_duration).should be
      video.instance_variable_get(:@convert_options).should == {}
      video.instance_variable_get(:@thumbs_options).should == {}

      video.instance_variable_get(:@path).should == "/root/test/path"
      video.instance_variable_get(:@name).should == "path"
    end

    it "raises error on nonexistent file" do
      File.stub!(:exists?) { raise "test.error" }
      expect { VTools::Video.new "nonextitent/path" }.to raise_error
    end
  end
end
