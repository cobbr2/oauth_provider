module OAuthProvider
  module Backends
    class DataMapper
      class Consumer
        include ::DataMapper::Resource

        # easiest way to get it to setup in the right repo.
        decorate :default_repository_name, :ez

        property :id, Serial
        property :callback, String, :unique => true, :required => true, :length => 2**8 - 1
        property :shared_key, String, :unique => true, :required => true
        property :secret_key, String, :unique => true, :required => true

        has n, :user_requests, :model => '::OAuthProvider::Backends::DataMapper::UserRequest'
        has n, :user_accesses, :model => '::OAuthProvider::Backends::DataMapper::UserAccess'

        def token
          OAuthProvider::Token.new(shared_key, secret_key)
        end

        def to_oauth(backend)
          OAuthProvider::Consumer.new(backend, backend.provider, callback, token)
        end
      end
    end
  end
end
