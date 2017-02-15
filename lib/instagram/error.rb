module Instagram
  # Custom error class for rescuing from all Instagram errors
  class Error < StandardError
    attr_reader :http_body
    attr_reader :http_headers
    attr_reader :http_status
    attr_reader :json_body
    attr_reader :method
    attr_reader :request_url

    def initialize(response={})
      @http_body = error_body(response[:body]) || ""
      @http_headers = response[:response_headers] || {}
      @http_status = response[:status] || nil
      @json_body = response[:body] || ""
      @method = response[:method].to_s.upcase || ""
      @request_url = response[:url].to_s || ""
    end

    def to_s
      "#{@method} #{@request_url}: #{@http_status}: #{@http_body}"
    end

    private

    def error_body(body)
      # body gets passed as a string, not sure if it is passed as something else from other spots?
      if not body.nil? and not body.empty? and body.kind_of?(String)
        # removed multi_json thanks to wesnolte's commit
        body = begin
          ::JSON.parse(body)
        rescue JSON::ParserError => e
          # Pass HTML or plain text response back
          if e.message.match /unexpected token/
            body
          else
            raise e
          end
        end
      end

      if body.nil?
        nil
      elsif body['meta'] and body['meta']['error_message'] and not body['meta']['error_message'].empty?
        "#{body['meta']['error_message']}"
      elsif body['error_message'] and not body['error_message'].empty?
        "#{body['error_type']}: #{body['error_message']}"
      end
    end
  end

  # Raised when Instagram returns the HTTP status code 400
  class BadRequest < Error; end

  # Raised when Instagram returns the HTTP status code 403
  class Forbidden < Error; end

  # Raised when Instagram returns the HTTP status code 404
  class NotFound < Error; end

  # Raised when Instagram returns the HTTP status code 429
  class TooManyRequests < Error; end

  # Raised when Instagram returns the HTTP status code 500
  class InternalServerError < Error
    def initialize(response)
      super(response.merge(body: 'Something is technically wrong.'))
    end
  end

  # Raised when Instagram returns the HTTP status code 502
  class BadGateway < Error
    def initialize(response)
      super(response.merge(body: 'The server returned an invalid or incomplete response.'))
    end
  end

  # Raised when Instagram returns the HTTP status code 503
  class ServiceUnavailable < Error
    def initialize(response)
      super(response.merge(body: 'Instagram is rate limiting your requests or having internal issues.'))
    end
  end

  # Raised when Instagram returns the HTTP status code 504
  class GatewayTimeout < Error;
    def initialize(response)
      super(response.merge(body: '504 Gateway Time-out'))
    end
  end

  # Raised when a subscription payload hash is invalid
  class InvalidSignature < Error; end

  # Raised when Instagram returns the HTTP status code 429
  class RateLimitExceeded < Error; end
end
