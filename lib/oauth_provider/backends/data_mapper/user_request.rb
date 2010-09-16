module OAuthProvider
  module Backends
    class DataMapper
      class UserRequest
        include ::DataMapper::Resource

        # easiest way to get it to setup in the right repo.
        decorate :default_repository_name, :ez

        property :id, Serial
        property :consumer_id,  Integer,  :required => true
        property :authorized,   Boolean,  :required => true, :default => false
        property :shared_key,   String,   :required => true, :unique => true 
        property :secret_key,   String,   :required => true, :unique => true
        property :url,          String,   :required => true, :default => 'oob', :length => 2**8 - 1
        property :verifier,     String,   :required => false

        belongs_to :consumer , :model => '::OAuthProvider::Backends::DataMapper::Consumer'

        def token
          OAuthProvider::Token.new(shared_key, secret_key)
        end

        def to_oauth(backend)
          OAuthProvider::UserRequest.new(backend, consumer.to_oauth(backend), url, authorized, verifier, token)
        end
      end
    end
  end
end
