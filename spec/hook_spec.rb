require "spec_helper"
require "hook"

describe VTools::Hook do

  # hooks
  before do
    @hook = VTools::Hook.dup
    @hook.instance_variable_set(:@callbacks, {})
  end

  # specs
  context "#set" do

    it "sets valid action" do
      @hook.instance_variable_get(:@callbacks).should == {}

      block = lambda { |*args| nil }
      other_block = lambda { |*args| false }

      @hook.set :action_one, &block
      @hook.set "action_two", &other_block

      @hook.instance_variable_get(:@callbacks).should == {
        :action_one => [ block ], :action_two => [ other_block ]
      }
    end

    it "skips set when no block given" do
      @hook.set :action_one
      @hook.set :action_one
      @hook.set :action_two

      @hook.instance_variable_get(:@callbacks).should == {:action_one => [], :action_two => []}
    end
  end

  context "#exec" do

    it "executes valid callbacks" do
      # prepare data
      block_one   = lambda { |*args| nil }
      block_two   = lambda { |*args| nil }
      block_three = lambda { |*args| nil }
      @hook.instance_variable_set( :@callbacks, {:action_one => [block_one], :action_two => [block_two, block_three]} )

      block_one.should_receive(:call).with("one").once
      block_two.should_receive(:call).with("two", "and", "three").once
      block_three.should_receive(:call).with("two", "and", "three").once

      @hook.exec :action_one, "one"
      @hook.exec :action_two, "two", "and", "three"
    end

    it "skips empty or invalid callbacks" do
      @hook.instance_variable_set(:@callbacks, {:action_one => [], :action_two => "test"} )

      callbacks = @hook.instance_variable_get(:@callbacks)
      callbacks[:action_one].should_receive :each
      callbacks[:action_two].should_not_receive :each

      # nil can't be called so we just must ensure, that error is not raised
      expect { @hook.exec :action_one, "one" }.to_not raise_error
      expect { @hook.exec :action_two, "two", "and", "three" }.to_not raise_error
    end
  end

  context "#collection" do

    it "executes valid scope" do
      VTools::Hook.should_receive(:instance_eval).once

      VTools::Hook.collection do
        self.should be_a_kind_of(VTools::Hook)
        self.should respond_to(:set)
        self.should respond_to(:get)
        self.should respond_to(:collection)
      end
    end
  end
end
