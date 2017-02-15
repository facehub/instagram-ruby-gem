require 'faraday'
#if using typhoeus as the adapter uncomment these two requires to avoid seeing "Ethon::Errors::InvalidOption: The option: disable_ssl_peer_verification is invalid." (https://github.com/typhoeus/typhoeus/issues/270)
#require 'typhoeus'
#require 'typhoeus/adapters/faraday'

# @private
module FaradayMiddleware
  # @private
  class RaiseHttpException < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response|
        case response[:status].to_i
        when 400
          raise Instagram::BadRequest, response
        when 403
          raise Instagram::Forbidden, response
        when 404
          raise Instagram::NotFound, response
        when 429
          raise Instagram::TooManyRequests, response
        when 500
          raise Instagram::InternalServerError, response
        when 502
          raise Instagram::BadGateway, response
        when 503
          raise Instagram::ServiceUnavailable, response
        when 504
          raise Instagram::GatewayTimeout, response
        end
      end
    end

    def initialize(app)
      super app
      @parser = nil
    end
  end
end
