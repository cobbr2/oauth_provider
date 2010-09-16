module OAuthProvider
  class UserRequest
    def initialize(backend, consumer, url, authorized, verifier, token)
      @backend, @consumer, @url, @authorized, @verifier, @token = backend, consumer, url, authorized, verifier, token
    end
    attr_reader :consumer, :token, :verifier, :url

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

    # The authorization GUI should call this to get the URL to redirect
    # the user to. "url" only records what the client put in the oauth_url
    # parameter; this provides the additional oauth 1.0a query parameters.
    #
    # Returns nil if the url is 'oob', in which case you need to render
    # the verifier in a way you know the resource owner can use to get it
    # to the client (e.g., easily enter into their mobile).
    def callback
      return nil if @url == 'oob'
      sep = URI::parse(@url).query.nil? ? '?' : '&'
      return @url + "#{sep}oauth_token=#{token.shared_key}&oauth_verifier=#{@verifier}"
    end

    # Query string is used as the payload when the consumer
    # gets a request token. Should *not* contain the url
    # or verifier, but MUST contain the 1.0a url_verified
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
