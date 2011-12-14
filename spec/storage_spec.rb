require "spec_helper"
require "storage"

describe VTools::Storage do

  # hooks
  before do
    VTools::Storage.instance_variable_set(:@actions, {})
  end

  # specs
  let(:block) { proc {} }

  def valid_call method
    VTools::Storage.instance_variable_set( :@actions, { method.to_sym => block } )
    block.should_receive(:call)
    expect { VTools::Storage.method(method.to_sym).call }.to_not raise_error
  end

  def validate_exception method
    VTools::Storage.should_receive(:fails).with(method.to_sym).and_return { raise "test.error" }
    expect { VTools::Storage.method(method.to_sym).call }.to raise_error
  end

  context "#connect" do

    it "calls connect" do
      valid_call "connect"
    end

    it "raises exception" do
      validate_exception "connect"
    end
  end

  context "#recv" do

    it "calls recv" do
      valid_call "recv"
    end

    it "raises exception" do
      validate_exception "recv"
    end
  end

  context "#send" do

    it "calls send" do
      VTools::Storage.instance_variable_set( :@actions, :send => block )
      block.should_receive(:call).with("test.data")
      expect { VTools::Storage.send("test.data") }.to_not raise_error
    end

    it "raises exception" do
      VTools::Storage.should_receive(:fails).with(:send).and_return { raise "test.error" }
      expect { VTools::Storage.send("data") }.to raise_error("test.error")
    end
  end

  def valid_connector scope
    VTools::Storage.method(scope.to_sym).call &block
    scope["_action"] = ""
    VTools::Storage.instance_variable_get(:@actions).should == { scope.to_sym => block }
  end

  context "#connect_action" do

    it "connects proc" do
      valid_connector "connect_action"
    end
  end

  context "#recv_action" do

    it "connects proc" do
      valid_connector "recv_action"
    end
  end

  context "#send_action" do

    it "connects proc" do
      valid_connector "send_action"
    end
  end

  context "#setup" do

    it "executes valid scope" do
      VTools::Storage.should_receive(:instance_eval).once

      VTools::Storage.setup do
        self.should be_kind_of(VTools::Storage)
      end
    end
  end

  context "#fails" do
    it "raises error with valid message" do
      expect do
        VTools::Storage.method(:fails).call("test_method")
      end.to raise_error NotImplementedError, "VTools::Storage#test_method_action must be set"
    end
  end
end
