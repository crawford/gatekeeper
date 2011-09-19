$LOAD_PATH.unshift(Dir.pwd)
require 'test'

use Rack::ShowExceptions

run Test.new
