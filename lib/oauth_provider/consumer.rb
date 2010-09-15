module OAuthProvider
  class Consumer
    def initialize(backend, provider, callback, token)
      @backend, @provider, @callback, @token = backend, provider, callback, token
    end
    attr_reader :provider, :callback, :token

    def find_user_request(shared_key)
      @backend.find_user_request(shared_key) ||
        raise(UserRequestNotFound.new(shared_key))
    end

    def destroy_user_request(shared_key)
      @backend.destroy_user_request(shared_key) ||
        raise(UserRequestNotFound.new(shared_key))
    end

    def find_user_access(shared_key)
      @backend.find_user_access(shared_key) ||
        raise(UserAccessNotFound.new(shared_key))
    end

    # Raises InvalidCallbackUrl if no callback
    # is provided, it can't be parsed, or it's
    # not an HTTP URL (i.e., something we can
    # really expect to use in a Location: header.)
    def validate_callback(callback)
        raise(InvalidCallbackUrl.new(self,callback)) unless callback
        if callback == 'oob'
            $LOG.warn("Oauth consumer #{self.token.shared_key} claiming use of 'oob' for request token, will probably fail @ access token retrieval")  if $LOG
            return true 
        end
        begin

            uri = URI::parse(callback)
            return true if ["http","https"].include?(uri.scheme)

            $LOG.debug { "#{callback} invalid since unsupported scheme" } if $LOG
            raise InvalidCallbackUrl.new(self,callback)

        rescue URI::InvalidURIError => e
            $LOG.debug { "#{callback} invalid for #{e.message}" } if $LOG
            raise  InvalidCallbackUrl.new(self,callback)
            return false;
        end
    end

    # Callback is *required* by RFC5849 when getting
    # a request token See http://tools.ietf.org/html/rfc5849#section-2.1
    def issue_request(callback = nil, authorized = false, token = nil)
      validate_callback(callback)
      verifier = nil
      @backend.add_user_request(self, callback, authorized, verifier, token || Token.generate)
    end

    def shared_key
      @token.shared_key
    end

    def secret_key
      @token.secret_key
    end

    def ==(consumer)
      return false unless consumer.is_a?(Consumer)
      [callback, token] == [consumer.callback, consumer.token]
    end
  end
end
