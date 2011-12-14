require "spec_helper"
require "job"

describe VTools::Job do

  let (:config) { OpenStruct.new :action => "info", :file => "test/file"}
  let (:video) { @video }

  # hooks
  before do
    @video = double nil
    VTools::Video.stub!(:new).and_return video
    @job = VTools::Job.new config
  end

  # specs
  context "#execute" do

    def stub_methods
      VTools::Hook.stub!(:exec).and_return nil

      @video.stub(:get_info).and_return {"info.result"}
      @video.stub(:convert).and_return {"encoded.result"}
      @video.stub(:create_thumbs).and_return {"thumbs.result"}
    end

    def set_action action
      options = @job.instance_variable_get :@config
      options.action = action
      @job.instance_variable_set :@config, options
    end

    it "receives video info" do
      stub_methods
      set_action "info"

      VTools::Hook.should_receive(:exec).with(:job_started, @video, "info")
      VTools::Hook.should_receive(:exec).with(:job_finished, "info.result", @video, "info")
      @video.should_receive(:get_info)

      @job.execute.should == "info.result"
    end

    it "starts video encoding" do
      stub_methods
      set_action "convert"

      VTools::Hook.should_receive(:exec).with(:job_started, @video, "convert")
      VTools::Hook.should_receive(:exec).with(:job_finished, "encoded.result", @video, "convert")
      @video.should_receive(:convert)

      @job.execute.should == "encoded.result"
    end

    it "creates thumbnails" do
      stub_methods
      set_action "thumbs"

      VTools::Hook.should_receive(:exec).with(:job_started, @video, "thumbs")
      VTools::Hook.should_receive(:exec).with(:job_finished, "thumbs.result", @video, "thumbs")
      @video.should_receive(:create_thumbs)

      @job.execute.should == "thumbs.result"
    end
  end

  # specs
  context "#validate" do

    it "accepts options" do

      ["convert", "thumbs", "info"].each do |action|
        conf = config.dup
        conf.action = action
        conf.setup = "setup.test" unless action == "info"

        expect { @job.validate(conf).should == conf }.to_not raise_error
      end
    end

    it "rases exception with invalid config" do

      def validate_exception conf, message_rx
        expect { @job.validate(conf) }.to raise_error VTools::ConfigError, message_rx
      end


      ["convert", "thumbs", "info"].each do |action|
        # empty config
        conf = OpenStruct.new({})
        validate_exception conf, /Invalid action \(config: /

        # +action -file
        conf.action = action
        validate_exception conf, /Invalid action \(config: /

        # empty file
        conf.file = ""
        validate_exception conf, /Invalid action \(config: /

        # +file -config
        conf.file = "test/file"
        validate_exception conf, "Configuration is empty" unless action == "info"
      end
    end
  end

  # specs
  context "#initialize" do

    it "passes valid params" do

      VTools::Job.any_instance.stub(:validate).and_return { |obj| obj }

      job = nil
      expect { job = VTools::Job.new config }.to_not raise_error

      job.id.should == job.object_id
      job.instance_variable_get(:@config).should == config
      job.instance_variable_get(:@video).should == video
    end

    it "raises error on invalid config (validate)" do
      VTools::Job.any_instance.stub(:validate).and_return { raise "test.exception" }

      expect { job = VTools::Job.new config }.to raise_error "test.exception"
    end
  end

end
