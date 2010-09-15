module OAuthProvider
  class Provider
    def initialize(backend)
      @backend = backend
    end
	 attr_reader :backend

    # Request verification

    def issue_request(request)
      consumer = verify(request, :consumer)
      # See RFC5849 page 9: the callback is required.
      consumer.issue_request(OAuth::RequestProxy.proxy(request).oauth_callback)
    end

    def upgrade_request(request)
      verify(request, :request).upgrade(request)
    end

    def confirm_access(request)
      verify(request, :access)
    end

    # Consumer

    def consumers
      @backend.consumers
    end

    def add_consumer(callback, token = nil)
      @backend.add_consumer(self, callback, token || Token.generate)
    end

    def find_consumer(shared_key)
      @backend.find_consumer(shared_key) ||
        raise(ConsumerNotFound.new(shared_key))
    end

    def save_consumer(consumer)
      @backend.save_consumer(consumer)
    end

    def destroy_consumer(consumer)
      @backend.destroy_consumer(consumer)
    end

    private
    def verify(request, type, &block)
      result = nil

      signature = OAuth::Signature.build(request) do |shared_key,consumer_shared_key|
        consumer = find_consumer(consumer_shared_key)
        case type
        when :request
          result = consumer.find_user_request(shared_key)
          $LOG.debug { "signing :request with request and consumer #{result.secret_key} #{consumer.secret_key}" } if $LOG
          [result.secret_key, consumer.secret_key]
        when :access
          result = consumer.find_user_access(shared_key)
          $LOG.debug { "signing :access with access and consumer #{result.secret_key} #{consumer.secret_key}" } if $LOG
          [result.secret_key, consumer.secret_key]
        when :consumer
          result = consumer
          $LOG.debug { "signing :consumer with nil and consumer #{consumer.secret_key}" } if $LOG
          [nil, consumer.secret_key]
        else
          raise ArgumentError, "Type should be one of :request, :access or :consumer"
        end
      end

      if signature.verify
        result
      else
        raise VerficationFailed, "Signature verification failed: #{signature.signature} != #{signature.request.signature}"
      end
    end
  end
end
