# Library example

Library can be required via `-r` option

$ vtools start -- -r library

$ vtools start -- -r library.rb

```ruby
# -*- encoding: binary -*-

# path generator
VTools.path_generator do |file_name|

  storage_path = VTools::CONFIG[:PWD] + "/../test_storage"
  first = file_name[0...2]
  second = file_name[2...4]
  # create all parent dirs (storage... path .. ) ???
  if (error = `mkdir -p #{storage_path}/#{first}/#{second}`).empty?
    "#{storage_path}/#{first}/#{second}"
  else
    raise Exception, "Can't create storage dirs (#{error})"
  end
end

# storage setup
VTools::Storage.setup do

  connect_action do
    @mq = MQ.new
    print "----------- connected to the MQ -------\n"
  end

  # recieve data for processing
  recv_action do
    job = @mq.recv
    setup = "{\"set\" : \"flv_240p\", \"acodec\" : \"#{job}\" }"
    "{\"action\" : \"#{action}\", \"file\" : \"#{file}\", \"setup\" : #{setup} }"
  end

  send_action do |result|
    @mq.send "video.success #{result[:action]} "
    print "----------------> 'terminated' MQ sent (#{result[:data].to_json}) - action #{result[:action]}\n"
  end
end

# hooks
VTools::Handler.collection do

  set :job_started do |video, action|
    print "(#{video.name}) ------> job     | started | {#{video}} :: scope: #{action}\n"
  end

  set :in_convert do |video, status|

    # cgeate thumb each step
    current = (status * 1000).round / 10.0
    @count ||= 0;

    # generate thumbs on the fly
    if @count == 10
      @count = 0
      print "(#{video.name}) >>>>>>> add_thumb --------- #{current}%\n"
      video.create_thumbs :thumb_count => 1,
                          :time => current.to_i,
                          :postfix => current.to_i,
                          :width => 600
    end

    @count += 1

    print "(#{video.name}) +++++++ convert | status  | (#{current}%)\n"
  end

  set :in_thumb do |video, thumb|
    print "(#{video.name}) +++++++ generate| thumbs  | (#{thumb})\n"
  end

  set :before_convert do |video, command|
    print "(#{video.name}) ------- convert |scheduled| {#{video}}\n"
  end

  set :before_thumb do |video, config|
    print "(#{video.name}) ------- thumbs  |scheduled| {#{video}} :: (config: #{config})\n"
  end

  set :convert_error do |video|
    print "(#{video.name}) !!!!!!! convert | failed  | {#{video}}\n"
  end

  set :convert_success do |video|
    print "(#{video.name}) <------ convert |finished | {#{video}}\n"
  end

  set :thumb_success do |video, thumbs|
    if thumbs
      images = ":: "
      thumbs.each do |hash|
        images += "#{hash[:offset]}||"
      end
      images = "#{images} count:#{thumbs.count}"
    end
    print "(#{video.name}) <------ thumbs  |finished | {#{video}} #{images}\n"
  end

  set :job_finished do |result, video, action|
    print "(#{video.name}) <------ job     |finished | {#{video}} :: scope: #{action}\n"
  end
end
```
