$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'statum'
require 'rspec'
require 'rack/test'
require 'data_mapper'
require 'dm-rspec'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

configure :test do
  DataMapper.setup(:default, "sqlite::memory:")
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include DataMapper::Matchers
  config.mock_framework = :mocha
end

ENV['RACK_ENV'] = "test"

def app
  @app ||= Statum::Application
end

# quick convenience methods..

def fixtures_path
  "#{File.dirname(File.expand_path(__FILE__))}/fixtures"
end
