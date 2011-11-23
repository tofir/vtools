require "spec_helper"
require "config"

describe VTools::CONFIG do
  context "VTools::CONFIG" do

    before :all do
      @config = VTools::CONFIG.dup
      @config[:video_set] = VTools::CONFIG[:video_set].dup
      @config[:thumb_set] = VTools::CONFIG[:thumb_set].dup
    end

    before :each do
      VTools::CONFIG.replace @config.dup
      VTools::CONFIG[:video_set] = @config[:video_set].dup
      VTools::CONFIG[:thumb_set] = @config[:thumb_set].dup
    end

    # specs
    context "#load!" do

      it "executes configs without merge" do
        VTools::CONFIG[:config_file] = false

        VTools.should_not_receive(:keys_to_sym)
        VTools::CONFIG.should_not_receive(:append!)

        expect { VTools::CONFIG.load! }.to_not raise_error
      end

      it "merges configs sucessfully" do
        VTools::CONFIG[:config_file] = 'exsitent/file'
        YAML.stub!(:load_file).and_return { {} } # stub file access method

        VTools.should_receive(:keys_to_sym)
        VTools::CONFIG.should_receive(:append!)

        expect { VTools::CONFIG.load! }.to_not raise_error
      end

      it "breaks executing due to invalid yaml" do
        VTools::CONFIG[:config_file] = 'nonexsitent/file'
        expect { VTools::CONFIG.load! }.to raise_error VTools::ConfigError, /Invalid config data /
      end
    end

    context "#append!" do

      # common validator behavior
      def validate_data config_hash

        VTools::CONFIG.append! config_hash

        # validate data
        VTools::CONFIG.each do |name, content|
          if config_hash.include? name
            content.should == config_hash[name]
          else # the rest data should remain untouched
            content.should == @config[name]
          end
        end
      end

      it "merges permitted data directly" do
        data = {
          :ffmpeg_binary  => 'binary-ffmpeg',
          :thumb_binary   => 'binary-ffmpeg',

          :max_jobs       => 'jobs',
          :harvester_timer=> 'timer',
          :temp_dir       => 'temp',

          :video_storage  => 'videos',
          :thumb_storage  => 'thumbs',
        }

        validate_data data
      end

      it "merges permitted data as array" do
        data = { :library  => ['data-lib'], }

        validate_data data
      end

      it "merges permitted data as hash" do
        data = {
          :video_set    => {:test => [1, 2, 3]},
          :thumb_set    => {:test => [1, 2, 3]},
        }

        VTools::CONFIG.append! data

        # validate data
        VTools::CONFIG.each do |name, content|
          if data.include?(name)
            content.should include(data[name])
            content[:test].should == data[name][:test]
          else # the rest data should remain
            content.should == @config[name]
          end
        end
      end

      it "skips denied data" do
        invalid_data = {
          :video_set   => {:test => 3},
          :thumb_set   => :test,
          :library  => 'data-lib',
        }

        # save original values
        VTools::CONFIG.append! invalid_data

        # invalid data should not be placed & the rest data should remain the same
        VTools::CONFIG.each { |key| VTools::CONFIG[key].should == @config[key] }
      end

      it "merges permitted & skips denied data (complex)" do

        mixed_data = {
          :video_set   => {
            :invalid  => 3,
            :valid    => [1,2,3],
          },
          :thumb_set => {
            :valid    => [1,2,3],
          },
          :library  => 'invalid',
        }
        VTools::CONFIG.append! mixed_data

        VTools::CONFIG[:thumb_set].should include :valid
        VTools::CONFIG[:thumb_set][:valid].should == mixed_data[:thumb_set][:valid]

        VTools::CONFIG[:video_set].should_not include :valid
        VTools::CONFIG[:video_set].should_not include :invalid
        VTools::CONFIG[:library].should_not include 'invalid'
      end
    end
  end
end