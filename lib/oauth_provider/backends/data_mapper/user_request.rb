module OAuthProvider
  module Backends
    class DataMapper
      class UserRequest
        include ::DataMapper::Resource

        property :id, Serial
        property :consumer_id, Integer, :required => true
        property :authorized, Boolean, :default => false, :required => true
        property :shared_key, String, :unique => true, :required => true
        property :secret_key, String, :unique => true, :required => true

        belongs_to :consumer , :model => '::OAuthProvider::Backends::DataMapper::Consumer'

        def token
          OAuthProvider::Token.new(shared_key, secret_key)
        end

        def to_oauth(backend)
          OAuthProvider::UserRequest.new(backend, consumer.to_oauth(backend), authorized, token)
        end
      end
    end
  end
end
