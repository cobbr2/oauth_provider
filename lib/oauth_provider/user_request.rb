module OAuthProvider
  class UserRequest
    def initialize(backend, consumer, callback, authorized, verifier, token)
      @backend, @consumer, @callback, @authorized, @verifier, @token = backend, consumer, callback, authorized, verifier, token
    end
    attr_reader :consumer, :token, :verifier

    def authorized?
      @authorized
    end

    def generate_verifier
      # Verifier doesn't have to be very long (probably shouldn't be, if we want
      # to support devices where it might have to be entered by hand, 
      # but has to be cryptographically random). Twitter's is so short they call
      # it a PIN.
      return OAuth::Helper.generate_key(4)
    end

    def authorize
      @verifier   = generate_verifier
      @authorized = true
      @backend.save_user_request(self)
    end

    def upgrade(request_proxy,token = nil)
      raise UserRequestNotYetAuthorized.new(self)       unless authorized?

      oauth_verifier = OAuth::RequestProxy.proxy(request_proxy).oauth_verifier 
      raise UserRequestVerifierMismatch.new(self,oauth_verifier) unless @verifier == oauth_verifier

      @backend.add_user_access(self, token || Token.generate)
    end

    # Callback is used when the user authorizes the transaction, so it
    # must contain both the request token key itself, and the oauth_verifier.
    # If you get nil in your response, you should render the oauth verifier
    # in a way that's easy for a limited-access-device user to enter.
    def callback
      $LOG.debug { "Using OAuth 1.0a request-specific callback #{callback}" }   if $LOG
      return nil if @callback == 'oob'
      sep = URI::parse(@callback).query.nil? ? '?' : '&'
      return @callback + "#{sep}oauth_token=#{token.shared_key}&oauth_verifier=#{@verifier}"
    end

    # Query string is used as the payload when the consumer
    # gets a request token. Should *not* contain the callback
    # or verifier, but MUST contain the 1.0a callback_verified
    # indication string.
    def query_string
      @token.query_string + "&oauth_callback_verified=true"
    end

    def shared_key
      @token.shared_key
    end

    def secret_key
      @token.secret_key
    end

    def ==(user_request)
      return false unless user_request.is_a?(UserRequest)
      [consumer, authorized?, token] == [user_request.consumer, user_request.authorized?, user_request.token]
    end
  end
end
