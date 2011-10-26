$LOAD_PATH.unshift(Dir.pwd)
require 'main'
require 'rack-webauth/test'

#TODO: Vendor the rack-webauth gem (uses String#any? instead of String#empty?)
use Rack::Webauth::Test, :user => "abcrawf"

use Rack::Webauth
use Rack::ShowExceptions

run Main.new
