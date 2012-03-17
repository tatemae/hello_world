require 'rack/utils'
require 'cgi'

module Slurper
  module Rack

    # A middle ware to parse cookies. This will parse the cookies and place them into
    # the cookies hash of the Goliath::Env for the request.
    #
    # @example
    #  use Slurper::Rack::Cookies
    #
    class Cookies
      
      include Goliath::Rack::Validator
          
      def initialize(app)
        @app = app
      end

      def call(env)
        Goliath::Rack::Validator.safely(env) do
          if env['HTTP_COOKIE']
            env['cookies'] = CGI::Cookie::parse(env['HTTP_COOKIE'])
          else
            env['cookies'] = {}
          end
          @app.call(env)
        end
      end
      
    end
  end
end