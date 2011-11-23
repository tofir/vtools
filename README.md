# VTools

Daemon tools to operate the video (get info, encode & generate thumbnails).
Under the hood ffmpeg & ffmpegthumbnailer are used.
Some ideas has been taken at the streamio-ffmpeg gem (parse output methods).

Project was developed for the [WebTV](http://web.tv)

## Installation

  (sudo) gem install vtools

Please read changelog to check ffmpeg versions compatibility (vtools understands 0.7 & 0.8).

## Usage

### Getting started

Before start, daemon should be configured correctly, to have valid access to the storage.
Mandatory methods are: **connect**, **recv** and **send**.

``` ruby
#--file library.rb--#
# encoding: binary

#to setup storage:
VTools::Storage.setup do

  # connection setup
  connect_action do
    # ... connect to the storage (persistent)
  end

  # message reciever
  # should return JSON encoded string
  # see complete storage setup reference for details
  recv_action do
    # ... job data recieve algorithm
  end

  # message sender
  # recieves hash: { :data => execution_result, :action => executed_action }
  # execution_result can be video object or array with thumbnails
  send_action do |result|
    # ... send action here
  end
end

# storage can be setup separate
VTools::Storage.connect_action do
  # ... connect to the storage
end
```

### Setup message (JSON)

```
{ "action" : "convert|thumbs|info", "file" : "path/to/file", "setup" :  < setup > }
# setup can be:
# -- "predefined_set_id"
# -- { ffmpeg_options_hash }
# -- { "set": "predefined_set_str", ffmpeg_options_hash }
```

### User friendly option names

```
converter (ffmpeg)
  preserve_aspect   (true or false)
  extension         (result file extension)
  width, height
  resolution
  duration

thumbnailer (ffmpegthumbnailer)
  thumb_count
  thumb_start_point (in percents)
  time              (time offset, alias for -t)
  quality           (0 - 10)
  width
```

## Start

To launch daemon - is enough to require library with storage setup:
  (sudo) vtools start -- -r library

## Options

### Daemon options are
  start
  stop
  restart

### Application options are:
  -c or --config-file - load config from file
  -r or --require     - load ruby library file (can be used more than once)

### To see complete options list use
  vtools --help

### Using logger

By default the `logger` gem is used. But there is possibility to set custom logger, that is compatible with the default logger.

``` ruby
VTools.logger = CustomLoger.new($stdout)
```

### Additioinal methods

Path generator is used by the thumnailer, converter or both to generate necessary dir tree logic for the media.
It accepts file name and should return relative path (excluding file name itself)

``` ruby
# path generator (used to )
VTools.path_generator do |file_name|
  # ..
  "#{file_name[0..2]}/{file_name[2..4]}"
end

```

**Network calls** (TCP GET request, that will return message body content, ignoring response headers)

``` ruby

# http calls
VTools.network_call "site.com/some/uri"
VTools.network_call "www.site.com"
VTools.network_call "http://www.site.com"
```
