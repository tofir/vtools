# Using hooks

Multiple actions can be attached for a single hook.

**hooks placeholders:**

* job_started (video, action)
* job_finished (result, video, action)

* before_convert (video, command)
* in_convert (video, progress)
* convert_success (video, output_file)
* convert_error (video, error, ffmpeg_output)

* before_thumb (video, config)
* in_thumb (video, thumb)
* thumb_success (video, thumbs_array)
* thumb_error (video, errors)

```ruby
# multiple hooks setup
VTools::Hook.collection do
  set :in_convert do |video|
    #..
  end

  set :in_thumb do |video|
    #..
  end
  # ...
end

# single hook setup
VTools::Hook.set :job_started do
  #..
end
```
