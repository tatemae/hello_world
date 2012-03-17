#!/usr/bin/env ruby
#$:<< '../lib' << 'lib'

#!/usr/bin/env ruby
$: << File.dirname(__FILE__)

require 'rubygems'
require "bundler/setup"

Bundler.require(:default)

require 'ruby-debug'

require 'goliath'

class HelloWorld < Goliath::API
  use Goliath::Rack::Params
  def response(env)
    debugger
    [200, {}, env.params[:hello]]
  end
end