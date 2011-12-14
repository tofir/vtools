# Library example

Library can be required via `-r` option

$ vtools start -- -r library

$ vtools start -- -r library.rb

```ruby
# encoding: binary


# path generator
VTools.path_generator("video") do |file_name|

  first = file_name[0...2]
  second = file_name[2...4]
  # create all parent dirs (storage... path .. )
  error = `mkdir -p #{VTools::CONFIG[:video_storage]}/#{first}/#{second}`
  if error.empty?
    "#{first}/#{second}"
  else
    raise Exception, "Can't create storage dirs (#{error})"
  end
end


# setup storage:
VTools::Storage.setup do

  # connection setup
  connect_action do
    require "zmq"
    @mq = ZMQ::Context.new(1)

    @pull = @mq.socket(ZMQ::PULL)
    @push = @mq.socket(ZMQ::PUSH)

    # connect to the mq fibers
    @pull.bind("tcp://*:4440");
    @push.connect("tcp://*:5555");
  end

  # message reciever
  # should return JSON encoded string
  # see complete storage setup reference for details
  recv_action do
    @pull.recv
  end

  # message sender
  # receives hash: { :data => execution_result, :action => executed_action }
  # execution_result can be video object or array with thumbnails
  send_action do |result|
    @push.send "#{result[:action]} #{result[:data].name}" if result[:action] =~ /convert|info/
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
