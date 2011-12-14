# -*- encoding: binary -*-

["..", "../../lib", "../../lib/vtools"].each do |path|
  dir = File.expand_path(path, __FILE__)
  $:.unshift dir if dir and not $:.include?(dir)
end

require "vtools"
require "rspec"
require "stringio"

# helpers utilities
module Helpers

end

RSpec.configure do |c|
  c.include Helpers
end
