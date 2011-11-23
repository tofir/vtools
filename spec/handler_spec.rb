require "spec_helper"
require "handler"

describe VTools::Handler do

  # hooks
  before do
    @handler = VTools::Handler.dup
    @handler.instance_variable_set(:@callbacks, {})
  end

  # specs
  context "#set" do

    it "sets valid action" do
      @handler.instance_variable_get(:@callbacks).should == {}

      block = lambda { |*args| nil }
      other_block = lambda { |*args| false }

      @handler.set :action_one, &block
      @handler.set "action_two", &other_block

      @handler.instance_variable_get(:@callbacks).should == {
        :action_one => [ block ], :action_two => [ other_block ]
      }
    end
    
    it "skips set when no block given" do
      @handler.set :action_one
      @handler.set :action_one
      @handler.set :action_two

      @handler.instance_variable_get(:@callbacks).should == {:action_one => [], :action_two => []}
    end
  end

  context "#exec" do

    it "executes valid callbacks" do
      # prepare data
      block_one   = lambda { |*args| nil }
      block_two   = lambda { |*args| nil }
      block_three = lambda { |*args| nil }
      @handler.instance_variable_set( :@callbacks, {:action_one => [block_one], :action_two => [block_two, block_three]} )

      block_one.should_receive(:call).with("one").once
      block_two.should_receive(:call).with("two", "and", "three").once
      block_three.should_receive(:call).with("two", "and", "three").once

      @handler.exec :action_one, "one"
      @handler.exec :action_two, "two", "and", "three"
    end

    it "skips empty or invalid callbacks" do
      @handler.instance_variable_set(:@callbacks, {:action_one => [], :action_two => "test"} )

      callbacks = @handler.instance_variable_get(:@callbacks)
      callbacks[:action_one].should_receive :each
      callbacks[:action_two].should_not_receive :each

      # nil can't be called so we just must ensure, that error is not raised
      expect { @handler.exec :action_one, "one" }.to_not raise_error
      expect { @handler.exec :action_two, "two", "and", "three" }.to_not raise_error
    end
  end

  context "#collection" do

    it "executes valid scope" do
      VTools::Handler.should_receive(:instance_eval).once

      VTools::Handler.collection do
        self.should be_a_kind_of(VTools::Handler)
        self.should respond_to(:set)
        self.should respond_to(:get)
        self.should respond_to(:collection)
      end
    end
  end
end
