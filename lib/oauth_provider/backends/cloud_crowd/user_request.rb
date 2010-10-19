module OAuthProvider
  module Backends
    class CloudCrowd
      class UserRequest
        include ::DataMapper::Resource

        # easiest way to get it to setup in the right repo.
        decorate :default_repository_name, :ez
        storage_names[:ez] = "ez_apps_user_requests"

        property :id, Serial
        property :consumer_id,  Integer,  :required => true, :index => true
        property :authorized,   Boolean,  :required => true, :default => false
        property :shared_key,   String,   :required => true, :unique => true 
        property :secret_key,   String,   :required => true
        property :url,          String,   :required => true, :default => 'oob', :length => 2**8 - 1
        property :verifier,     String,   :required => false

        # Cloudcrowd almost always wants these as a forensic tool.
        property :created_at,   DateTime
        property :updated_at,   DateTime

        belongs_to :consumer , :model => '::OAuthProvider::Backends::CloudCrowd::Consumer'
        belongs_to :customer , :model => '::Ez::Customer', :required => false

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
