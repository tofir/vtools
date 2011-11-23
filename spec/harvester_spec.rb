require "spec_helper"
require "harvester"

describe VTools::Harvester do

  # hooks
  before do
    @harvester = VTools::Harvester.dup
  end

  context "#add_job" do

    def stub_methods

      Thread.stub!(:new) do |*args, block|
        block.call(*args)
      end

      job_mock = double(nil)
      job_mock.stub(:id).and_return 10
      job_mock.stub(:execute).and_return "test.executed"

      VTools::Job.stub!(:new).and_return { job_mock }

      @harvester.stub!(:finish).and_return nil
      @harvester.stub!(:with_error_handle).and_return { |blk| blk.call }
      job_mock
    end

    it "accepts valid config" do

      config = OpenStruct.new(:action => "test.action")
      job = stub_methods

      VTools::Storage.stub!(:send).and_return do |hsh|
        hsh.should include :data => "test.executed", :action => "test.action"
      end

      @harvester.should_receive(:finish).with(job).twice
      VTools::Storage.should_receive(:send).twice
      VTools::Job.should_receive(:new).with(config).twice

      @harvester.add_job config
      @harvester.add_job config

      @harvester.instance_variable_get(:@jobs).should include 10 => job, 10 => job
      @harvester.instance_variable_get(:@run_jobs).should == 2
    end
  end

  context "#finish" do

    def make_stubs ret = true
      VTools::Job.stub!(:id).and_return 10
      VTools::Job.stub!(:is_a?).and_return ret
    end

    it "accepts data" do
      make_stubs

      job = VTools::Job

      # place job
      @harvester.instance_variable_set :@jobs, 10 => true
      @harvester.instance_variable_set :@run_jobs, 2

      @harvester.method(:finish).call(job)

      @harvester.instance_variable_get(:@jobs).should_not include 10 => true
      @harvester.instance_variable_get(:@run_jobs).should == 1
    end

    it "denies data" do
      make_stubs

      job = VTools::Job

      # place job
      @harvester.instance_variable_set :@jobs, 1 => true
      @harvester.instance_variable_set :@run_jobs, 2

      jobs = @harvester.instance_variable_get(:@jobs)
      jobs.should_not_receive(:delete)

      @harvester.method(:finish).call(job)

      jobs.should include 1 => true
      @harvester.instance_variable_get(:@run_jobs).should == 2
    end

    it "non Job passed" do
      make_stubs false

      job = VTools::Job

      jobs = @harvester.instance_variable_get(:@jobs)
      jobs.should_not_receive(:delete)

      @harvester.method(:finish).call(job)
    end
  end

  context "#with_error_handle" do

    def handle_error type, message_rx
      @harvester.stub(:log).and_return do |e_level, mess|
        e_level.should == type
        mess.should =~ message_rx
      end
    end

    it "passes data with no exception" do
      expect { @harvester.method(:with_error_handle).call }.to_not raise_error
      expect { @harvester.method(:with_error_handle).call {a = "some block"} }.to_not raise_error
    end

    it "raises known exception" do
      handle_error :error, /test\.error/

      [VTools::ConfigError, VTools::FileError, VTools::FormatError, VTools::ProcessError].each do |execpt|
        @harvester.should_receive(:log)

        expect do
          @harvester.method(:with_error_handle).call { raise execpt, "test.error" }
        end.to_not raise_error
      end
    end

    it "raises unknown exception" do
      handle_error :fatal, /test\.fatal/
      @harvester.should_receive(:log).with(:fatal, "test.fatal")

      expect do
        @harvester.method(:with_error_handle).call { raise "test.fatal" }
      end.to raise_error
    end
  end

  # specs
  context "#daemonize!" do

    def stub_methods
      @harvester.stub!(:loop).and_return{ |block| block.yield }
      @harvester.stub!(:sleep)

      VTools::Storage.stub!(:connect).and_return nil
      VTools::Storage.stub!(:recv).and_return "recvd"
      @harvester.stub!(:with_error_handle).and_return {|blk| blk.call}
    end

    # CONFIG[:max_jobs] > @run_jobs, should[_not]_receive [__messages__]
    it "loops trough jobs" do
      stub_methods

      config = OpenStruct.new( :config => 'tested' )
      @harvester.stub!(:json_to_obj).and_return { config }

      VTools::CONFIG[:harvester_timer] = 0
      VTools::CONFIG[:max_jobs] = 2
      @harvester.instance_variable_set :@run_jobs, 1

      @harvester.should_receive(:sleep).with(0).once
      VTools::Storage.should_receive(:connect).once
      VTools::Storage.should_receive(:recv).once
      @harvester.should_receive(:json_to_obj).with("recvd").once
      @harvester.should_receive(:add_job).with(config).once
      @harvester.should_receive(:with_error_handle).once

      @harvester.daemonize!
    end

    it "does not takes job (queue if full)" do
      stub_methods

      VTools::CONFIG[:harvester_timer] = 1
      VTools::CONFIG[:max_jobs] = 2
      @harvester.instance_variable_set :@run_jobs, 2

      @harvester.should_receive(:sleep).with(1).once
      VTools::Storage.should_receive(:connect).once
      VTools::Storage.should_not_receive(:recv)
      @harvester.should_not_receive(:json_to_obj)
      @harvester.should_not_receive(:add_job)
      @harvester.should_not_receive(:with_error_handle)

      @harvester.daemonize!
    end
  end
end
