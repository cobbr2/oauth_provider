module OAuthProvider
  module Backends
    class CloudCrowd
      class UserAccess
        include ::DataMapper::Resource

        # easiest way to get it to setup in the right repo.
        decorate :default_repository_name, :ez

        property :id, Serial
        property :consumer_id, Integer, :required => true
        property :request_shared_key, String, :required => true
        property :shared_key, String, :unique => true, :required => true
        property :secret_key, String, :unique => true, :required => true

        belongs_to :consumer , :model => '::OAuthProvider::Backends::CloudCrowd::Consumer'
        belongs_to :customer , :model => '::Ez::Customer'

        def token
          OAuthProvider::Token.new(shared_key, secret_key)
        end

        def to_oauth(backend)
          OAuthProvider::UserAccess.new(backend, consumer.to_oauth(backend), request_shared_key, token, {:customer => customer})
        end
      end
    end
  end
end
