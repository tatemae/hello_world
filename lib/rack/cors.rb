require 'rack/utils'
require 'cgi'

module Slurper
  module Rack

    # A middle ware to handle CORS requests. Technique from http://www.tsheffler.com/blog/?p=428
    #
    # @example
    #  use Slurper::Rack::Cors
    #
    class Cors
      
      include Goliath::Rack::AsyncMiddleware
      
      def initialize(app, opts = {})
        @app = app
      end
       
      def call(env)
        if env['REQUEST_METHOD'] == 'OPTIONS'
          # If this is a preflight OPTIONS request, then short-circuit the
          # request, return only the necessary headers and return an empty
          # text/plain.
          headers = cors_common_headers
          headers['Access-Control-Allow-Headers'] = 'X-Requested-With, Content-Type'
          headers['Content-Type'] = 'text/plain'
          [200, headers, '']
        else
          super(env)
        end
      end

      # For all responses, return the CORS access control headers.
      def post_process(env, status, headers, body)
        headers ||= {}
        [status, cors_common_headers.merge(headers), body]
      end
      
      def cors_common_headers
        {
          'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => 'POST, GET, OPTIONS',
          'Access-Control-Max-Age' => "1728000"  
        }
      end
      
    end
  end
end