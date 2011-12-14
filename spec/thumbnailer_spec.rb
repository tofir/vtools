require "spec_helper"
require "thumbnailer"

describe VTools::Thumbnailer do

  let(:video)  { double (nil) }

  # hooks
  before do
    @thumbnailer = VTools::Thumbnailer.new video
  end

  # specs
  context "#run" do

    before do
      @output_file = nil
      @options = {}
    end

    def prepare_thumbnailer error_strings = []
      # prepare output lines
      index = 0
      # output iterator (raise error once per item)
      Open3.stub!(:popen3).and_return do |*args, block|
        (io = StringIO.new(error_strings[index].to_s)).rewind
        block.yield(nil, io, nil)
        index += 1
      end

      @options.stub(:to_s) { "test.options" }

      video.stub(:thumbs_options) { @options }
      video.stub(:name) { "video.name" }
      video.stub(:path) { "video/path" }
      @converter.instance_variable_set( :@video, video )

      VTools::CONFIG[:thumb_binary] = "tested.thumbnailer"
      @output_file = "/#{video.name}_"

      VTools.should_receive(:fix_encoding).exactly(@options[:thumb_count].to_i).times.and_return {|str| str}
      VTools::Hook.should_receive(:exec).with(:before_thumb, video, @options)
      @thumbnailer.should_receive(:generate_path)
    end

    it "creates thumbnails without postfix" do

      @options = {:thumb_count => 3, :thumb_start_point => 0}
      prepare_thumbnailer

      thumbs_array = [
        {:path => "#{@output_file}0.jpg", :offset => 0},
        {:path => "#{@output_file}1.jpg", :offset => 1},
        {:path => "#{@output_file}2.jpg", :offset => 2},
      ]

      thumbs_array.each do |index|
        VTools::Hook.should_receive(:exec).with(:in_thumb, video, index)
      end

      @thumbnailer.should_receive(:set_point).exactly(3).times.and_return { |sec| sec }
      @thumbnailer.should_receive(:time_offset).exactly(3).times.and_return { |sec| (sec.is_a?(Hash) ? sec[:thumb_start_point] : sec) }
      VTools::Hook.should_receive(:exec).with(:thumb_success, video, thumbs_array)

      @thumbnailer.run.should == thumbs_array
    end

    it "creates thumb with postfix and offset" do

      @options = {:thumb_count => 1, :thumb_start_point => 3, :postfix => "test.postfix"}
      prepare_thumbnailer

      thumbs_array = [ {:path => "#{@output_file}test.postfix.jpg", :offset => 3} ]

      VTools::Hook.should_receive(:exec).with(:in_thumb, video, thumbs_array[0])

      @thumbnailer.should_receive(:set_point).once.and_return { |sec| sec }
      @thumbnailer.should_receive(:time_offset).once.and_return { |sec| sec[:thumb_start_point] }
      VTools::Hook.should_receive(:exec).with(:thumb_success, video, thumbs_array)

      @thumbnailer.run.should == thumbs_array
    end

    it "creates thumbs via options[:t]" do
      @options = {:t => 12, :thumb_count => 1}
      prepare_thumbnailer

      thumbs_array = [ {:path => "#{@output_file}12.jpg", :offset => 12} ]

      VTools::Hook.stub(:exec)
      @thumbnailer.should_not_receive(:set_point)
      @thumbnailer.should_receive(:time_offset).with(12).once.and_return { |sec| sec }

      @thumbnailer.run.should == thumbs_array
    end

    it "creates 2 of 3 thumbs" do
      @options = {:thumb_count => 3, :thumb_start_point => 0}
      prepare_thumbnailer ["thumbnailer error"]

      thumbs_array = [
        {:path => "#{@output_file}1.jpg", :offset => 1},
        {:path => "#{@output_file}2.jpg", :offset => 2},
      ]

      VTools::Hook.should_receive(:exec).with(:thumb_error, video, " Errors: thumbnailer error (/video.name_0.jpg). ")
      thumbs_array.each do |index|
        VTools::Hook.should_receive(:exec).with(:in_thumb, video, index)
      end

      @thumbnailer.should_receive(:set_point).exactly(3).times.and_return { |sec| sec }
      @thumbnailer.should_receive(:time_offset).exactly(2).times.and_return { |sec| (sec.is_a?(Hash) ? sec[:thumb_start_point] : sec) }

      @thumbnailer.run.should == thumbs_array
    end

    it "completely fails on thumb creation" do
      @options = {:thumb_count => 2, :thumb_start_point => 0}
      prepare_thumbnailer ["thumbnailer error", "thumbnailer error 2"]


      VTools::Hook.should_receive(:exec).with(
        :thumb_error, video,
        " Errors: thumbnailer error (/video.name_0.jpg);thumbnailer error 2 (/video.name_1.jpg). "
      )

      @thumbnailer.should_not_receive(:time_offset)
      @thumbnailer.should_receive(:set_point).exactly(2).times.and_return { |sec| sec }

      expect { @thumbnailer.run }.to raise_error VTools::ProcessError, /Thumbnailer error:/
    end

    it "processes invalid encoding" do
      @options = {:thumb_count => 1, :thumb_start_point => 0}
      prepare_thumbnailer [
        File.readlines(
          "#{File.realpath(File.dirname(__FILE__))}/fixtures/outputs/file_with_iso-8859-1.txt"
        )[10]
      ]

      VTools::Hook.should_receive(:exec).with(:thumb_error, video, / Errors: /)

      @thumbnailer.should_not_receive(:time_offset)
      @thumbnailer.should_receive(:set_point).and_return { |sec| sec }

      expect { @thumbnailer.run }.to raise_error VTools::ProcessError, /Thumbnailer error:/
    end
  end

  context "#set_point" do

    context "generates percent point from hash" do
      it "indicated in percent" do
        config = {:thumb_start_point => "12.2%"}
        @thumbnailer.method(:set_point).call(config).should == 12
      end

      it "indicated in seconds" do
        config = { :thumb_start_point => 122 }
        @thumbnailer.should_receive(:time_offset).with("122")

        @thumbnailer.method(:set_point).call(config)
      end
    end

    it "generates percent point from integer" do
      @thumbnailer.instance_variable_set(:@total, 3) # total count
      @thumbnailer.method(:set_point).call(1).should == 33 # first pic
      @thumbnailer.method(:set_point).call(2).should == 66
      @thumbnailer.method(:set_point).call(3).should == 100 # last pic
    end

    it "returns default" do
      @thumbnailer.method(:set_point).call("invalid").should == 0
    end
  end

  context "#time_offset" do

    let(:video) {v = double nil; v.stub(:duration){120.3}; v}

    before { @thumbnailer.instance_variable_set(:@video, video) }

    it "calculates offset from valid shift value" do
      @thumbnailer.method(:time_offset).call(10).should == "00:00:10"
      @thumbnailer.method(:time_offset).call(23.2).should == "00:00:23"
    end

    it "shift value is invalid returns video duration" do
      @thumbnailer.method(:time_offset).call(123).should == "00:02:00"
      @thumbnailer.method(:time_offset).call(130).should == "00:02:00"
    end
  end
end
