module OAuthProvider
  module Backends
    class CloudCrowd
      class Consumer
        include ::DataMapper::Resource

        # easiest way to get it to setup in the right repo.
        decorate :default_repository_name, :ez

        property :id,           Serial
        property :callback,     String, :unique => true, :required => true, :length => 2**8 - 1
        property :shared_key,   String, :unique => true, :required => true
        property :secret_key,   String, :unique => true, :required => true
        property :app_name,     String, :unique => true, :length => 2**8 - 1

        has n, :user_requests, :model => '::OAuthProvider::Backends::CloudCrowd::UserRequest'
        has n, :user_accesses, :model => '::OAuthProvider::Backends::CloudCrowd::UserAccess'

        # We want names in our models, but the app to populate them doesn't exist yet.
        def name
            return app_name || callback
        end

        def token
          OAuthProvider::Token.new(shared_key, secret_key)
        end

        # FIXME: oauth_provider.git doesn't support extending its underlying models well.
        #
        # This handles the extension (e.g., to put a name in, or a link to an application
        # developer model) for the consumer, but it's a bit ugly.
        # 
        # Just passing the model up seems cleaner, off-hand, than the way I did the parameters
        # for the user access token. OTOH, that one has more interesting requirements --
        # temporarily persisting the user information with the request token -- so I'd want to take
        # my time before unifying the two approaches.
        #
        def to_oauth(backend)
          OAuthProvider::Consumer.new(backend, backend.provider, callback, token, { :model => self })
        end
      end
    end
  end
end
