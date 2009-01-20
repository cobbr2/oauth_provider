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

    def find_user_access(shared_key)
      @backend.find_user_access(shared_key) ||
        raise(UserAccessNotFound.new(shared_key))
    end

    def issue_request
      @backend.add_user_request(self)
    end

    def shared_key
      @token.shared_key
    end

    def secret_key
      @token.secret_key
    end

    def ==(consumer)
      [callback, token] == [consumer.callback, consumer.token]
    end
  end
end
