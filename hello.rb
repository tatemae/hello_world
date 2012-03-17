#!/usr/bin/env ruby
$: << File.dirname(__FILE__)

require 'rubygems'
require "bundler/setup"

Bundler.require(:default)

require 'ruby-debug'

require 'goliath'
require 'lib/rack/cors'

class HelloWorld < Goliath::API
  use Goliath::Rack::Params
  use Slurper::Rack::Cors
  
  def response(env)
    debugger
    env[:foo] = 'test'
    [200, {}, env.params[:hello]]
  end
end