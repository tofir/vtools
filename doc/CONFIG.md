# Using config file (YAML)

To make VTools parse config file it should be given to it with -c option:

    $ vtools start -- -c config.json


## Format

    #system
    :ffmpeg_binary:     'ffmpeg'
    :thumb_binary:      'ffmpegthumbnailer'
    :library:           ['lib.rb']

    #harvester
    :max_jobs:          5
    :harvester_timer:   3  # timeout between job requests
    :temp_dir:          "/tmp"

    #converter
    :validate_duration: false
    :video_storage:     "/home/projects/storage/video"

    #thumbnailer
    :thumb_storage:     "/home/projects/storage/thumb"

    #predefined video qualities
    :video_set:
        # SET_NAME    -vcodec     -acodec    -s WDTxHGT      -vb       -ab    -ar      -ac  EXT    POSTFIX   [-vpre]
        :x264_180p: [ 'libx264',  'libfaac',  '240x180',    '96k',    '64k',  22050,    2,  'mp4', '_180',   'normal'   ]

    # predefined thumbnailer setup
    :thumb_set:
        # SET_NAME   -s   -q count start%
        :w120s:   [  120, 10,  5,   0 ]
