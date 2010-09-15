module OAuthProvider
  class UserRequest
    def initialize(backend, consumer, callback, authorized, token)
      @backend, @consumer, @callback, @authorized, @token = backend, consumer, callback, authorized, token

    end
    attr_reader :consumer, :token

    def authorized?
      @authorized
    end

    def authorize
      @authorized = true
      @backend.save_user_request(self)
    end

    def upgrade(token = nil)
      if authorized?
        @backend.add_user_access(self, token || Token.generate)
      else
        raise UserRequestNotAuthorized.new(self)
      end
    end

    def callback
      $LOG.debug { "Using OAuth 1.0a request-specific callback #{callback}" }   if $LOG
      $LOG.warn { "FIXME: Should add my own token to this callback! Also verifier!" }   if $LOG
      return @callback
    end

    def query_string
      @token.query_string
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
