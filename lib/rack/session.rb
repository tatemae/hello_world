require 'rack/utils'
require 'rack/session/abstract/id'
require 'remcached'
require 'em-synchrony/em-remcached'

module Slurper
  module Rack
    class Session < ::Rack::Session::Abstract::ID
      
      include Goliath::Rack::AsyncMiddleware
      
      def initialize(app, options={})
        @app = app
        @default_options = self.class::DEFAULT_OPTIONS.merge(options)
        @key = @default_options.delete(:key)
        @cookie_only = @default_options.delete(:cookie_only)
        initialize_sid
        super(app)
      end
      
      def call(env)
        prepare_session(env)
        super(env)
      end

      # Add any required session cookies
      def post_process(env, status, headers, body)
        headers ||= {}
        status, headers, body = commit_session(env, status, headers, body)
        [status, headers, body]
      end
      
      def generate_sid
        exists = true
        sid = ''
        while exists do
          sid = super
          # Ensure the key doesn't already exist
          memcache_connect
          response = Memcached.get(key: sid)
          if response[:status] == Memcached::Errors::KEY_NOT_FOUND
            exists = false
          elsif response[:status] == Memcached::Errors::NO_ERROR
            # Key exists need to try again
          else
            raise "Error: #{status_message(response[:status])}. Memcache server: #{memcache_servers}"
          end
        end
        sid
      end
      
      def get_session(env, sid)
        session = nil
        memcache_connect(env)
        if sid
          response = Memcached.get(key: sid)
          if response[:status] == Memcached::Errors::NO_ERROR
            session = unmarshal(response[:value])
          else
            env.logger.info("*********************************************************")
            env.logger.info("Error getting session: '#{response.inspect}'")
          end
        end
        if !session
          sid ||= generate_sid
          session = {}
          response = Memcached.set(key: sid, value: session)
          unless response[:status] == Memcached::Errors::NO_ERROR
            env.logger.info("*********************************************************")
            env.logger.info("Error setting up new session: '#{response.inspect}'")
          end
        end
        [sid, session]
      end

      def set_session(env, sid, new_session, options)
        memcache_connect(env)
        set_with = {
          key: sid, 
          value: marshal(new_session)
        }
        expiry = options[:expire_after]
        set_with[:expiration] = expiry + 1 unless expiry.nil?
        response = Memcached.set(set_with)
        if response[:status] == Memcached::Errors::NO_ERROR
          sid
        else
          env.logger.info("*********************************************************")
          env.logger.info("Error setting session: '#{response.inspect}'")
          nil
        end
      end

      def destroy_session(env, sid, options)
        memcache_connect(env)
        Memcached.delete(key: sid)
        generate_sid unless options[:drop]
      end

      private
      
        def memcache_servers
          servers = @default_options[:memcache_server]
          servers = [servers] unless servers.is_a?(Array)
          servers
        end
        
        def memcache_connect(env = nil)
          if !Memcached.usable?
            if env
              env.logger.info("--------------------------------------------------------")
              env.logger.info("Connecting to memcache server: #{memcache_servers}")
              env.logger.info("--------------------------------------------------------")
            end
            Memcached.connect(memcache_servers)
            raise 'Memcache was not configured succesfully' if !Memcached.usable?
          end
        end
        
        def marshal(value)
          Marshal.dump(value)
        end

        def unmarshal(value)
          return value if value.nil?
          Marshal.load(value)
        end
        
        def status_message(status)
          case status
            when Memcached::Errors::KEY_EXISTS
              "Memcached: Key exists"
            when Memcached::Errors::KEY_NOT_FOUND
              "Memcached: Key not found"
            when Memcached::Errors::VALUE_TOO_LARGE
              "Memcached: Value to large"
            when Memcached::Errors::INVALID_ARGS
              "Memcached: Invalid Args"
            when Memcached::Errors::ITEM_NOT_STORED
              "Memcached: Item not stored"
            when Memcached::Errors::NON_NUMERIC_VALUE
              "Memcached: non numberic value"
            when Memcached::Errors::DISCONNECTED
              "Memcached: Disconnected"
            else
              "Memcached: Unknown error: #{status}"
          end
        end
        
    end
  end
end
