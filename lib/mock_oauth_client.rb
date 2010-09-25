
require 'oauth/request_proxy/base'

module OAuth
  module RequestProxy
    class MockRequest < OAuth::RequestProxy::Base
      proxies Hash

      def parameters
        @request["parameters"]
      end

      def method
        @request["method"].upcase
      end

      def uri
        @request["uri"]
      end
    end
  end
end

class OAuthClient
  def initialize(consumer)
    @consumer = OAuth::Consumer.new(consumer.shared_key, consumer.secret_key)
  end
  attr_reader :consumer

  def request(token = nil, extras = nil)
    Request.new(@consumer, Time.now.to_i, token, extras).signed_request
  end

  def mock_request(request_hash, token = nil, extras = nil)
    my_request = Request.new(@consumer, Time.now.to_i, token, extras, request_hash)
    signed_mock = my_request.signed_request
    signed_mock['headers'] ||= {}
    signed_mock['headers']['Authorization'] = my_request.header( extras ? extras[:realm] : nil )
    return signed_mock
  end

  class Request
    include OAuth::Helper

    # use params to set additional query parameters like
    # oauth_callback or oauth_verifier (1.0a)
    def initialize(consumer, timestamp, token, params = nil, request_data = nil)
      @consumer, @timestamp, @nonce, @token, @params, @request_data = consumer, timestamp, generate_key, token, params, request_data
      @params = {} unless @params;
      @request_data = {} unless @request_data;
    end

    def signed_request
      r = request
      r["parameters"]["oauth_signature"] = signature
      r
    end

    def signature
      OAuth::Signature.sign(request) do |token|
        [@token && @token.secret_key, @consumer.secret]
      end
    end

    def request
      @request_data['method'] = 'GET'                unless @request_data['method']
      @request_data['uri']    = 'http://example.org' unless @request_data['uri']
      @request_data['parameters'] = query_hash
      @request_data
    end

    # Copied code from OAuth::Client::Helper, couldn't figure out a way
    # to make the objects share in a way I could live with.
    def header(realm = nil)
      signed_request unless @request_data['parameters']['oauth_signature']
      # FIXME: Shouldn't include non-oauth parameters in the header value, even if they're included in the signature calculation
      header_params_str = @request_data['parameters'].sort.map { |k,v| "#{k}=\"#{OAuth::Helper.escape(v)}\"" }.join(', ')

      realm = "realm=\"#{realm}\", " if realm
      return "OAuth #{realm}#{header_params_str}"
    end

    def query_hash
      h = @params
      h.merge!({"oauth_nonce" => @nonce,
           "oauth_timestamp" => @timestamp,
           "oauth_signature_method" => "HMAC-SHA1",
           "oauth_consumer_key" => @consumer.key,
           "oauth_version" => "1.0"})
      h["oauth_token"] = @token.shared_key if @token
      h
    end
  end
end
