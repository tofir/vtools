# -*- encoding: binary -*-

# default configuration options
module VTools

  CONFIG = {

    # system environment
    :PWD                  => Dir.getwd,
    :library              => [],
    :logging              => nil,
    :log_file             => nil,
    :config_file          => nil,
    :ffmpeg_binary        => '/usr/bin/ffmpeg',
    :thumb_binary         => '/usr/bin/ffmpegthumbnailer',

    # harvester
    :max_jobs             => 5,
    :store_jobs           => 10,
    :harvester_timer      => 3,
    :temp_dir             => '',

    # converter
    :video_storage        => '',
    :video_path_generator => nil,
    :validate_duration    => nil,

    # thumbnailer
    :thumb_storage        => '',
    :thumb_path_generator => nil,

    # predefined video qualities
    :video_set => {
      # SET_NAME     -vcodec VC   -acodec AC -s WDTxHGT    -vb BR    -ab BR -ar SMPL -ac CH EXT POSTFIX -vpre CONF
      :x264_180p  => ['libx264',  'libfaac',  '240x180',    '96k',    '64k',  22050, 2, 'mp4', '_180',  'normal' ],
      :x264_240p  => ['libx264',  'libfaac',  '426x240',    '128k',   '64k',  22050, 2, 'mp4', '_240',  'normal' ],
      :x264_360p  => ['libx264',  'libfaac',  '640x360',    '480k',   '128k', 44100, 2, 'mp4', '_360',  'normal' ],
      :x264_480p  => ['libx264',  'libfaac',  '845x480',    '720k',   '128k', 44100, 2, 'mp4', '_480',  'normal' ],
      :x264_720p  => ['libx264',  'libfaac',  '1280x720',   '1024k',  '128k', 44100, 2, 'mp4', '_720',  'normal' ],
      :x264_1080p => ['libx264',  'libfaac',  '1920x1080',  '2048k',  '128k', 44100, 2, 'mp4', '_1080', 'normal' ],

      :mp4_180p   => ['mpeg4',    'libfaac',  '240x180',    '96k',    '64k',  22050, 2, 'mp4', '_180',           ],
      :mp4_240p   => ['mpeg4',    'libfaac',  '426x240',    '128k',   '64k',  22050, 2, 'mp4', '_240',           ],
      :mp4_360p   => ['mpeg4',    'libfaac',  '640x360',    '480k',   '128k', 44100, 2, 'mp4', '_360',           ],
      :mp4_480p   => ['mpeg4',    'libfaac',  '845x480',    '720k',   '128k', 44100, 2, 'mp4', '_480',           ],
      :mp4_720p   => ['mpeg4',    'libfaac',  '1280x720',   '1024k',  '128k', 44100, 2, 'mp4', '_720',           ],
      :mp4_1080p  => ['mpeg4',    'libfaac',  '1920x1080',  '2048k',  '128k', 44100, 2, 'mp4', '_1080',          ],

      :flv_180p   => ['flv',      'libfaac',  '240x180',    '96k',    '64k',  22050, 2, 'flv', '_180',           ],
      :flv_240p   => ['flv',      'libfaac',  '426x240',    '128k',   '64k',  22050, 2, 'flv', '_240',           ],
      :flv_360p   => ['flv',      'libfaac',  '640x360',    '480k',   '128k', 44100, 2, 'flv', '_360',           ],
      :flv_480p   => ['flv',      'libfaac',  '845x480',    '720k',   '128k', 44100, 2, 'flv', '_480',           ],
      :flv_720p   => ['flv',      'libfaac',  '1280x720',   '1024k',  '128k', 44100, 2, 'flv', '_720',           ],
      :flv_1080p  => ['flv',      'libfaac',  '1920x1080',  '2048k',  '128k', 44100, 2, 'flv', '_1080',          ],
    },

    # predefined thumbnailer setup
    :thumb_set => {
      #         -s  -q count start%
      :w120 => [120, 10, 5, 0],
      :w240 => [240, 10, 5, 0],
      :w360 => [360, 10, 5, 0],
      :w360 => [480, 10, 5, 0],
      :w600 => [600, 10, 5, 0],
    }
  }

  # parse external config file
  def CONFIG.load!
    begin
      data = YAML.load_file self[:config_file]
      data = VTools.keys_to_sym data
      append! data
    rescue => e
      raise ConfigError, "Invalid config data #{e}"
    end if self[:config_file]
  end

  # merge config data
  def CONFIG.append! data
    direct = [:ffmpeg_binary, :thumb_binary, :max_jobs, :store_jobs,
      :harvester_timer, :temp_dir, :video_storage, :thumb_storage]
    # common data
    merge! data.select { |key, value| direct.include?(key) }

    self[:library] += data[:library] if data[:library].is_a? Array # libs

    [:video_set, :thumb_set].each do |index| # predefined video & thumbs
      self[index].merge! data[index] if
        data[index].is_a?(Hash) &&
        data[index].values.reject{ |val| val.is_a? Array}.empty?
    end
  end
end # VTools::CONFIG
