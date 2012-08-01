$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'rubygems'
require 'statum'

run Statum::Application
