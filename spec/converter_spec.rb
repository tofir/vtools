require "spec_helper"
require "converter"

describe VTools::Converter do

  # hooks
  before do
    @converter = VTools::Converter.new nil
  end

  let(:video) { double nil }

  # specs
  context "#run" do

    let(:output_array)  { [] }
    let(:ffmpeg_7) { {10.02 => "time=10.02", 15.34 => "time=15.34", 20.45 => "time=20.45"} }
    let(:ffmpeg_8) { {10.02 => "time=00:00:10.02", 15.34 => "time=00:00:15.34", 20.45 => "time=00:00:20.45", 61.05 => "time=00:01:01.05"} }
    let(:ffmpeg_no_time) { {0.0 => "broken pipe"} }

    # hooks
    before do
      @output_file = nil
      @options = {}
    end


    def prepare_converter values_set
      # prepare output lines
      output_array.push *values_set.values
      # output iterator
      (io = double(nil)).stub!(:each) { |*args, blk| output_array.each { |line| blk.yield(line) } }
      Open3.stub!(:popen3).and_return{ |*args, block| block.yield(nil, nil, io) }

      @options.should_receive(:to_s).and_return { "test.options" }

      video.stub(:convert_options){ @options }
      video.stub(:name) {"video/name"}
      video.stub(:path) {"video/path"}
      video.stub(:duration) { values_set.keys.last }

      @converter.instance_variable_set(:@video, video)

      VTools::CONFIG[:ffmpeg_binary] = "tested.ffmpeg"
      @output_file = "/#{video.name}#{@options[:postfix]}.#{@options[:extension]}"
      # "#{CONFIG[:ffmpeg_binary]} -y -i '#{@video.path}' #{@options} '#{@output_file}'"
      exec_com = "tested.ffmpeg -y -i 'video/path' test.options '#{@output_file}'"

      VTools::Handler.should_receive(:exec).with(:before_convert, video, exec_com)
      VTools.should_receive(:fix_encoding).exactly(values_set.size).times
      @converter.should_receive(:generate_path)
    end

    it "converts video for ffmpeg 0.7" do
      prepare_converter ffmpeg_7

      ffmpeg_7.each do |sec, time_str|
        VTools::Handler.should_receive(:exec).with(:in_convert, video, sec/ffmpeg_7.keys.last)
      end

      VTools::Handler.should_receive(:exec).with(:convert_success, video, @output_file)
      @converter.should_receive(:encoding_invalid?) { false }
      @converter.should_receive(:encoded)

      @converter.run
    end

    it "converts video for ffmpeg 0.8" do
      prepare_converter ffmpeg_8

      ffmpeg_8.each do |sec, time_str|
        VTools::Handler.should_receive(:exec).with(:in_convert, video, sec/ffmpeg_8.keys.last)
      end

      VTools::Handler.should_receive(:exec).with(:convert_success, video, @output_file)
      @converter.should_receive(:encoding_invalid?) { false }
      @converter.should_receive(:encoded)

      @converter.run
    end
    
    context "fails encoding" do

      it "--no time received" do
        prepare_converter ffmpeg_no_time
        expect { @converter.run }.to raise_error VTools::ProcessError, "broken pipe"
      end

      it "--result file is invalid" do
        VTools::Handler.stub(:exec).and_return nil
        prepare_converter ffmpeg_7
        @converter.should_receive(:encoding_invalid?) { "test.fail" }
        expect { @converter.run }.to raise_error VTools::ProcessError, "test.fail"
      end
    end
  end

  context "#encoding_invalid?" do

    before do
      VTools::CONFIG[:validate_duration] = nil
    end

    def prepare_converter
      File.stub!(:exists?).and_return { true }
      video.stub(:duration) { 200.2 } # set duration in sec
      @converter.stub_chain(:encoded, :valid?).and_return { true }
      @converter.instance_variable_set(:@video, video)
    end

    context "encoding is valid" do

      it "no manual duration set" do
        prepare_converter
        @converter.instance_variable_set(:@options, {}) # no manual duration set
        @converter.stub_chain(:encoded, :duration).and_return { 200.2 }
        VTools::CONFIG[:validate_duration] = true

        @converter.encoding_invalid?.should == false
      end

      it "duration set manually" do
        prepare_converter
        @converter.instance_variable_set(:@options, { :duration => 115.3 }) # manual duration set
        @converter.stub_chain(:encoded, :duration).and_return { 115.3 }
        VTools::CONFIG[:validate_duration] = true

        @converter.encoding_invalid?.should == false
      end

      it "without duration test" do
        prepare_converter
        @converter.encoding_invalid?.should == false
      end
    end

    context  "encoding is invalid" do

      it "no encoded file" do
        File.stub!(:exists?).and_return { false }
        @converter.encoding_invalid?.should == "No output file created"
      end

      it "encoded media is invalid video instance" do
        File.stub!(:exists?).and_return { true }
        @converter.stub_chain(:encoded, :valid?).and_return { false }
        @converter.encoding_invalid?.should == "Encoded file is invalid"
      end

      it "invalid duration auto" do
        prepare_converter
        VTools::CONFIG[:validate_duration] = true
        @converter.instance_variable_set(:@options, { :duration => 115.3 }) # no manual duration set
        @converter.stub_chain(:encoded, :duration).and_return { 220.2 } # original 220
        @converter.encoding_invalid?.should =~ /Encoded file duration is invalid \(original\/specified:/
      end

      it "invalid duration manual" do
        prepare_converter
        VTools::CONFIG[:validate_duration] = true
        @converter.instance_variable_set(:@options, {}) # no manual duration set
        @converter.stub_chain(:encoded, :duration).and_return { 320.2 } # original 220
        @converter.encoding_invalid?.should =~ /Encoded file duration is invalid \(original\/specified:/
      end
    end
  end
end
