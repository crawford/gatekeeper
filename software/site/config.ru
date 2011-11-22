$LOAD_PATH.unshift(Dir.pwd)
require 'main'

Dir.mkdir('tmp') unless Dir.exists?('tmp')
$stdout.reopen(File.new('tmp/stdout.log', 'a'))
$stderr.reopen(File.new('tmp/stderr.log', 'a'))

use Rack::ShowExceptions

run Main.new
