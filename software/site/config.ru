$LOAD_PATH.unshift(Dir.pwd)
require 'main'

use Rack::ShowExceptions

run Main.new
