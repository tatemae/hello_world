#!/usr/bin/env ruby
#$:<< '../lib' << 'lib'

#!/usr/bin/env ruby
$: << File.dirname(__FILE__)

require 'rubygems'
require "bundler/setup"

Bundler.require(:default)


require 'goliath'

class HelloWorld < Goliath::API
  def response(env)
    [200, {}, "hello world"]
  end
end