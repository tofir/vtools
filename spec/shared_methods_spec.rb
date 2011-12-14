require "spec_helper"
require "shared_methods"

describe VTools::SharedMethods do

  class Tested
  end

  # hooks
  before do
    @class = Tested.new
  end

  # specs
  context "::Common" do

    class Tested
      include VTools::SharedMethods::Common

      def initialize
        @@logger = nil
      end

      def test_logger
        @@logger
      end
    end

    # hooks
    before do
      @class = Tested.new
    end

    context "#logger=" do

      it "appends logger" do
        @class.logger = "test.logger"
        @class.test_logger.should == "test.logger"
      end
    end

    context "#log" do

      let(:tester) { double(nil) }

      def stub_methods
        tester.stub(:level=).and_return nil
        Logger.stub!(:new).and_return { tester }
      end

      before do
        VTools::CONFIG[:logging] = nil
      end

      it "skips log (logging disable)" do
        tester.stub(:send).and_return nil

        @class.logger = tester
        tester.should_not_receive :send

        @class.log :test, "test"
      end

      it "creates logger and send message" do
        VTools::CONFIG[:logging] = true

        stub_methods
        Logger::INFO = "test.level"

        Logger.should_receive(:new).with(STDOUT, 1000, 1024000).once
        tester.should_receive(:level=).with("test.level").once
        tester.should_receive(:send).with(:test_level, "test.log").once

        @class.log :test_level, "test.log"
      end

      it "creates valid log message to existing logger" do
        VTools::CONFIG[:logging] = true

        stub_methods

        Logger.should_not_receive(:new)
        tester.should_not_receive(:level=)
        tester.should_receive(:send).with(:test_level, "test.log").once

        @class.logger = tester
        @class.log :test_level, "test.log"
      end
    end

    context "#json_to_obj" do

      it "calls valid chain" do
        @class.stub(:parse_json).and_return { |jstr| "parsed.#{jstr}" }
        @class.stub(:hash_to_obj).and_return { |js| "hashed.#{js}" }

        @class.json_to_obj("JSON").should == "hashed.parsed.JSON"
      end
    end

    context "#hash_to_obj" do

      it "calls exception" do
        OpenStruct.stub!(:new).and_return { raise "test exception" }
        expect { @class.hash_to_obj "test" }.to raise_error VTools::ConfigError, "Can't convert setup to object"
      end
      it "accepts hash" do
        OpenStruct.stub!(:new).and_return "hash accepted"
        expect { @class.hash_to_obj(:test_key => "test.value").should == "hash accepted" }.to_not raise_error
      end
    end

    context "#parse_json" do

      it "raises exception on invalid json" do
        JSON.stub!(:parse).and_return { raise "test.execption" }
        expect { @class.parse_json("invalid json") }.to raise_error VTools::ConfigError, "Invalid JSON"
      end

      it "parses json" do
        JSON.stub!(:parse).and_return "JSON.parsed"
        expect { @class.parse_json("valid json").should == "JSON.parsed" }.to_not raise_error
      end
    end

    context "#keys_to_sym" do

      it "fails execution on non Hash" do
        @class.keys_to_sym("non Hash").should == "non Hash"
      end

      it "converts string keys to symbols" do
        @class.keys_to_sym(:key => "one", "other_key" => "two").should == { :key => "one", :other_key => "two" }
      end
    end

    context "#config" do

      it "returns config index" do
        VTools::CONFIG[:test_index] = "test.value"

        @class.config(:test_index).should == "test.value"
        @class.config(:nonexistent_index).should be nil
      end
    end

    context "#network_call" do

      let(:sock) { double nil }
      let(:tcp_request) { "GET / HTTP/1.0\r\n\r\n" }

      def validate_request body
        sock.should_receive(:print).with( tcp_request ).once
        sock.should_receive(:read).once.and_return "headers\r\n\r\n#{body}"
        sock.should_receive(:close).once
      end

      it "creates tcp request with default settings" do

        TCPSocket.should_receive(:open).with("localhost", 80).once.and_return {sock}
        validate_request "body"
        expect do
          @class.network_call("tcp://localhost").should == "body"
        end.to_not raise_error
      end

      it "creates tcp request" do
        tcp_request["/"] = "/test/address"

        TCPSocket.should_receive(:open).with("server.com", 8080).once.and_return {sock}
        validate_request "test body"
        expect do
          @class.network_call("http://server.com:8080/test/address").should == "test body"
        end.to_not raise_error
      end

      it "fails tcp request" do

        TCPSocket.should_receive(:open).once.and_return { raise "test exception" }
        @class.should_receive(:log).once.and_return {|l| l.should == :error}
        expect { @class.network_call("") }.to_not raise_error
      end
    end

    context "#generate_path" do

      it "returns valid string" do
        VTools::CONFIG[:video_storage] = "test/path/"
        VTools::CONFIG[:thumb_storage] = "/thumb/path"

        @class.generate_path("test.filename").should == "test/path"
        @class.generate_path("test.filename", "thumb").should == "/thumb/path"

        VTools::CONFIG[:thumb_storage] = ''

        VTools::CONFIG[:PWD] = "test/pwd"
        @class.generate_path("test.filename", "thumb").should == "test/pwd"

        VTools::CONFIG[:PWD] = nil
        VTools::CONFIG[:thumb_storage] = nil

        @class.generate_path("test.filename", "thumb").should == ""
      end

      it "executes block" do
        prc = proc do |file|
          file.should == "test.filename"
          self.class.should == Tested
          "test/path"
        end

        VTools::CONFIG[:video_storage] = '/root/'
        VTools::CONFIG[:video_path_generator] = prc
        @class.generate_path("test.filename", "video").should == "/root/test/path"

        VTools::CONFIG[:thumb_storage] = 'root'
        VTools::CONFIG[:thumb_path_generator] = prc
        @class.generate_path("test.filename", "thumb").should == "root/test/path"
      end

      it "raises exception on invalid block" do
        prc = proc do
          CONFIG[:thumb_storage]
        end

        VTools::CONFIG[:video_path_generator] = prc
        expect do
          @class.generate_path("test.filename", "video").should == "/root/test/path"
        end.to raise_error VTools::ConfigError, /Path generator error/
      end
    end

    context "#path_generator" do

      before do
        VTools::CONFIG[:video_storage] = nil
        VTools::CONFIG[:thumb_storage] = nil
        VTools::CONFIG[:thumb_path_generator] = nil
        VTools::CONFIG[:video_path_generator] = nil
      end

      let(:block) { proc { nil } }

      it "appends generator to thumbs" do
        @class.path_generator "thumb", &block
        VTools::CONFIG[:thumb_path_generator].should == block
        VTools::CONFIG[:video_path_generator].should be nil
      end

      it "appends generator to thumbs (invalid placeholedr given)" do
        @class.path_generator "invalid", &block
        VTools::CONFIG[:thumb_path_generator].should == block
        VTools::CONFIG[:video_path_generator].should be nil
      end

      it "appends generator to video" do
        @class.path_generator "video", &block
        VTools::CONFIG[:video_path_generator].should == block
        VTools::CONFIG[:thumb_path_generator].should be nil
      end

      it "appends generator to both (default)" do
        @class.path_generator &block
        VTools::CONFIG[:video_path_generator].should == block
        VTools::CONFIG[:thumb_path_generator].should == block
      end

      it "skips generator appending" do
        @class.path_generator
        VTools::CONFIG[:video_path_generator].should be nil
        VTools::CONFIG[:thumb_path_generator].should be nil
      end
    end

    context "#fix_encoding" do

      it "fixes encoding" do
        path = "#{File.realpath(File.dirname(__FILE__))}/fixtures/outputs/"
        source = File.open("#{path}file_with_iso-8859-1.txt", "r").read
        @class.fix_encoding(source).encoding.to_s.should match(/iso-8859-1/i)
      end
    end
  end # ::Common

  context "::Static" do

    class Tested
      include VTools::SharedMethods::Static
    end

    # hooks
    before do
      @class = Tested.new
    end

    context "#load_libs" do

      # CONFIG[:library]
      # require lib
      # rescue LoadError => e
      #      print "Library file could not be found (#{lib})\n"
      #    rescue SyntaxError => e
      #      print "Library may contain non ascii characters (#{lib}).\n\n" +
      #        "Try to set file encoding to 'binary'.\n\n"
      #    end
      before do
        VTools::CONFIG[:library] = []
      end

      it "requires libraries" do
        libs = ["one", "two", "three"]
        VTools::CONFIG[:library] = libs

        libs.each do |lib|
          @class.should_receive(:require).with(lib)
        end

        @class.load_libs
      end

      it "raises not found error" do
        VTools::CONFIG[:library] << "one"

        @class.stub(:require).and_return { raise LoadError }
        @class.should_receive(:print).with("Library file could not be found (one)\n")
        @class.load_libs
      end

      it "raises syntax error" do
        VTools::CONFIG[:library] << "one"

        @class.stub(:require).and_return { raise SyntaxError }
        @class.should_receive(:print).with("Library may contain non ascii characters (one).\n\nTry to set file encoding to 'binary'.\n\n")
        @class.load_libs
      end
    end
  end

  context "::Instance" do
  end

  context "#included" do
    it "appends methods correctly" do
      class Tested
        include VTools::SharedMethods
      end

      class CommonTest
        include VTools::SharedMethods::Common
      end

      class StaticTest
        include VTools::SharedMethods::Static
      end

      class InstanceTest
        include VTools::SharedMethods::Instance
      end

      (CommonTest.methods + StaticTest.methods - Object.methods).each do |m|
        Tested.should respond_to m
      end

      @tested = Tested.new
      (CommonTest.methods + InstanceTest.methods - Object.methods).each do |m|
        @tested.should respond_to m
      end
    end
  end
end
